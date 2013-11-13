# to draw states graph execute:
#   rake state_machine:draw FILE=invoice.rb CLASS=ReceivedInvoice
class ReceivedInvoice < InvoiceDocument

  unloadable

  after_create :create_event

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

  def original=(s)
    write_attribute(:original, compress(s))
  end

  def original
    decompress(read_attribute(:original))
  end

  protected

  def create_event
    Event.create(:name=>'validating_format',:invoice=>self,:md5=>md5)
  end

  private

  def compress(string)
    return nil if string.nil?
    buf = ActiveSupport::Gzip.compress(string)
    Base64::encode64(buf).chomp
  end

  def decompress(string)
    return nil if string.nil?
    begin
      buf = Base64::decode64(string)
      ActiveSupport::Gzip.decompress(buf)
    rescue
      string
    end
  end

end
