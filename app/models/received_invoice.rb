# to draw states graph execute:
#   rake state_machine:draw FILE=invoice.rb CLASS=ReceivedInvoice
class ReceivedInvoice < InvoiceDocument

  unloadable

  attr_accessor :md5
  after_create :create_event
  before_save :update_status, :unless => Proc.new {|invoicedoc| invoicedoc.state_changed? }

  state_machine :state, :initial => :validating_format do
    before_transition do |invoice,transition|
      unless Event.automatic.include?(transition.event.to_s)
        Event.create(:name=>transition.event.to_s,:invoice=>invoice,:user=>User.current)
      end
    end

    event :success_validating_format do
      transition :validating_format => :validating_signature
    end
    event :error_validating_format do
      transition :validating_format => :error
    end
    event :discard_validating_format do
      transition :validating_format => :error
    end
    event :success_validating_signature do
      transition [:validating_format, :validating_signature] => :received
    end
    event :error_validating_signature do
      transition [:validating_format, :validating_signature] => :error
    end
    event :discard_validating_signature do
      transition [:validating_format, :validating_signature] => :error
    end
    event :refuse do
      transition [:accepted,:received,:error] => :refused
    end
    event :accept do
      transition [:received,:error,:accepted] => :accepted
    end
    event :paid do
      transition :accepted => :paid
    end
    event :unpaid do
      transition :paid => :accepted
    end
  end

  def initialize(attributes)
    super
    self.has_been_read=false
  end

  def total
    import
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

  def valid_format?
    events.sort.each do |e|
      return true  if %w( success_validating_format ).include? e.name
      return false if %w( error_validating_format discard_validating_format ).include? e.name
    end
    return false
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
    Event.create(:name=>'validating_format',:invoice=>self,:md5=>md5)
  end

  def update_status
    if is_paid?
      paid if state?(:accepted)
    else
      unpaid if state?(:paid)
    end
    return true # always continue saving
  end

end
