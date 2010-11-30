class InvoiceLine < ActiveRecord::Base

  unloadable

  belongs_to :invoice
  validates_presence_of :description
  validates_numericality_of :quantity, :price_in_cents

  composed_of :price,
    :class_name => "Money",
    :mapping => [%w(price_in_cents cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter => lambda {|m| m.to_money }

  def initialize(attributes=nil)
    super
    update_currency
  end

  def total
    price * quantity
  end

  def to_label
    description
  end

  def template_replacements(date=nil)
    Utils.replace_dates! description, (date || Date.today) +  (invoice.frequency || 0).months
  end

  def tax
    total * (invoice.tax_percent / 100.0)
  end

  private

  def update_currency
    self.currency = self.invoice.currency rescue nil
    self.currency ||= self.invoice.client.currency rescue nil
    self.currency ||= self.invoice.company.currency rescue nil
    self.currency ||= Money.default_currency.iso_code
  end

end
