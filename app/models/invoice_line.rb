class InvoiceLine < ActiveRecord::Base

  unloadable

  belongs_to :invoice, :autosave => true
  validates_presence_of :description
  validates_numericality_of :quantity, :price_in_cents

  composed_of :price,
    :class_name => "Money",
    :mapping => [%w(price_in_cents cents)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0) },
    :converter => lambda {|m| m.to_money }

  def currency=(v)
  end

  def currency
    self.invoice.currency
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

end
