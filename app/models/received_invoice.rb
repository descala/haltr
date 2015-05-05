# to draw states graph execute:
#   rake state_machine:draw FILE=invoice.rb CLASS=ReceivedInvoice
class ReceivedInvoice < InvoiceDocument

  unloadable

  after_create :create_event
  before_save :update_imports

  state_machine :state, :initial => :received do
    before_transition do |invoice,transition|
      unless Event.automatic.include?(transition.event.to_s)
        Event.create(:name=>transition.event.to_s,:invoice=>invoice,:user=>User.current)
      end
    end

    event :refuse do
      transition [:accepted,:received] => :refused
    end
    event :accept do
      transition [:received,:accepted] => :accepted
    end
    event :paid do
      transition :accepted => :paid
    end
    event :unpaid do
      transition :paid => :accepted
    end
    event :processing_pdf do
      transition [:received] => :processing_pdf
    end
    event :processed_pdf do
      transition [:processing_pdf] => :received
    end
  end

  def to_label
    "#{number}"
  end

  def past_due?
    #TODO
    false
  end

  def label
    l(self.class)
  end

  def valid_signature?
    events.sort.each do |e|
      return true  if %w( success_validating_signature ).include? e.name
      return false if %w( error_validating_signature discard_validating_signature ).include? e.name
    end
    return false
  end

  # remove colons "1,23" => "1.23"
  def import=(v)
    i = Money.new(((v.is_a?(String) ? v.gsub(',','.') : v).to_f * 100).round, currency)
    write_attribute :import_in_cents, i.cents
  end

  protected

  def create_event
    ReceivedInvoiceEvent.create!(:name=>self.transport,:invoice=>self,:user=>User.current)
  end

end
