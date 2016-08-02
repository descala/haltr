class Quote < Invoice

  include Haltr::ExportableDocument

  has_one :invoice
  before_save :update_imports

  after_create do
    Event.create(:name=>"quote_new",:invoice=>self,:user=>User.current)
  end
  after_initialize do
    if !quote_expired? and due_date and Date.today > due_date and
      (quote_new? or quote_send? or quote_sent?)
      expired!
    end
  end
  before_save do
    if quote_expired?
      if !due_date or (due_date_changed? and due_date >= Date.today)
        write_attribute(:state, :quote_new)
      end
    end
  end

  include AASM

  aasm column: :state, skip_validation_on_save: true, whiny_transitions: false do
    state :quote_new, initial: true
    state :quote_send, :quote_accepted, :quote_sent, :quote_expired,
      :quote_sending, :quote_closed, :quote_refused

    before_all_events :aasm_create_event

    event :quote_set_new do
      transitions to: :quote_new
    end
    event :quote_accept do
      transitions to: :quote_accepted
    end
    event :quote_refuse do
      transitions to: :quote_refused
    end
    event :quote_close do
      transitions to: :quote_closed
    end
    event :quote_send do
      transitions to: :quote_sending
    end
    event :success_sending do
      transitions to: :quote_sent
    end
    event :expired do
      transitions from: [:quote_new,:quote_send,:quote_sent], to: :quote_expired
    end
  end

  def aasm_create_event
    name = aasm.current_event.to_s.gsub('!','')
    unless %w(success_sending expired).include? name
      Event.create(
        name: name,
        invoice: self,
        user_id: User.current
      )
    end
  end

  def self.last_number(project)
    numbers = project.quotes.collect {|i| i.number }.compact
    numbers.sort_by do |num|
      if num =~ /\d+/
        [2, $&.to_i] # $& contains the complete matched text
      else
        [1, num]
      end
    end.last
  rescue
    ""
  end

  def self.next_number(project)
    number = self.last_number(project)
    IssuedInvoice.increment_right(number)
  end

  def label
    l :label_quote
  end

  def past_due?
    quote_closed? && due_date && due_date < Date.today
  end

  def pdf_name_without_extension
    "#{l(:label_quote)}-#{number.gsub('/','')}" rescue "quote-___"
  end

  def has_been_sent?
    !quote_new?
  end

  def client_has_email
    unless self.recipient_emails.any?
      add_export_error(:client_has_no_email)
    end
  end

end
