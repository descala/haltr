class Quote < Invoice

  unloadable

  include Haltr::ExportableDocument

  belongs_to :invoice
  before_save :update_imports

  after_create do
    Event.create(:name=>"quote_new",:invoice=>self,:user=>User.current)
  end

  state_machine :state, :initial => :quote_new do
    before_transition do |invoice, transition|
      unless transition.event.to_s == "success_sending"
        Event.create(:name=>transition.event.to_s,:invoice=>invoice,:user=>User.current)
      end
    end
    event :quote_set_new do
      transition all => :quote_new
    end
    event :quote_accept do
      transition all => :quote_accepted
    end
    event :quote_refuse do
      transition all => :quote_refused
    end
    event :quote_close do
      transition all => :quote_closed
    end
    event :quote_send do
      transition all => :quote_sending
    end
    event :success_sending do
      transition all => :quote_sent
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

  def label
    l :label_quote
  end

  def past_due?
    !state?(:quote_closed) && due_date && due_date < Date.today
  end

  def pdf_name_without_extension
    "#{l(:label_quote)}-#{number.gsub('/','')}" rescue "quote-___"
  end

  def sent?
    !state?(:quote_new)
  end

  def client_has_email
    unless self.recipient_emails.any?
      add_export_error(l(:client_has_no_email))
    end
  end

end
