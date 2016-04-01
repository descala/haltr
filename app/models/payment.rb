class Payment < ActiveRecord::Base

  unloadable

  belongs_to :invoice
  belongs_to :project
  validates_numericality_of :amount_in_cents, :greater_than => 0

  after_save do
    old_invoice = InvoiceDocument.find invoice_id_was rescue nil
    invoice.reload if invoice # without this is_paid? returns false
    if old_invoice != invoice
      old_invoice.save(validate: false) if old_invoice.is_a? InvoiceDocument
    end
    invoice.save(validate: false) if invoice.is_a? InvoiceDocument
  end

  after_destroy do
    invoice.save(validate: false) if invoice.is_a? InvoiceDocument
  end

  before_save :guess_invoice, :unless => :invoice

  composed_of :amount,
    :class_name => "Money",
    :mapping => [%w(amount_in_cents cents)],
    :constructor => Proc.new { |cents| Money.new(cents || 0, Money::Currency.new(Setting.plugin_haltr['default_currency'])) },
    :converter => lambda {|m| Haltr::Utils.to_money(m) }

  def initialize(attributes=nil)
    super
    self.date ||= Date.today
  end

  def description
    desc = ""
    desc += self.payment_method unless self.payment_method.blank?
    desc += "#{' - ' if desc.size > 0}#{self.reference}" unless self.reference.blank?
  end

  def guess_invoice
    candidates = IssuedInvoice.candidates_for_payment self
    self.invoice = candidates.first if candidates
  end

  def self.new_to_close(invoice)
    if invoice.is_a?(InvoiceDocument)
      Payment.new(:invoice => invoice, :project => invoice.project, :amount => invoice.unpaid_amount)
    end
  end

end
