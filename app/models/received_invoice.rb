class ReceivedInvoice < InvoiceDocument

  unloadable

  after_create :create_event

  composed_of :subtotal,
    :class_name => "Money",
    :mapping => [%w(subtotal_in_cents cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) }

  composed_of :withholding_tax,
    :class_name => "Money",
    :mapping => [%w(withholding_tax_in_cents cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) }

  # new sending sent error discarded closed
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
      transition :validating_format => :non_electronic_invoice
    end
    event :discard_validating_format do
      transition :validating_format => :non_electronic_invoice
    end
    event :success_validating_signature do
      transition :validating_signature => :electronic_invoice
    end
    event :error_validating_signature do
      transition :validating_signature => :non_electronic_invoice
    end
    event :discard_validating_signature do
      transition :validating_signature => :non_electronic_invoice
    end
    event :refuse do
      transition [:accepted,:non_electronic_invoice,:electronic_invoice] => :refused
    end
    event :accept do
      transition [:electronic_invoice,:non_electronic_invoice] => :accepted
    end
    event :pay do
      transition :accepted => :paid
    end
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

  protected

  def create_event
    Event.create(:name=>'validating_format',:invoice=>self)
  end

end
