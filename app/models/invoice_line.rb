class InvoiceLine < ActiveRecord::Base

  unloadable

  belongs_to :invoice
  validates_presence_of :description
  validates_numericality_of :quantity, :price

  def initialize(attributes=nil)
    super
    update_currency
  end

  def total
    Money.new((price * quantity * 100).to_i, currency)
  end

  def to_label
    description
  end

  def template_replacements(date=nil)
    Utils.replace_dates! description, (date || Date.today) +  (invoice.frequency || 0).months
  end

  def tax
     if invoice.tax_percent
      total * (invoice.tax_percent / 100.0)
    else
      Money.new(0,currency)
    end
  end

  private

  def update_currency
    self.currency = self.invoice.currency rescue nil
    self.currency ||= self.invoice.client.currency rescue nil
    self.currency ||= self.invoice.company.currency rescue nil
    self.currency ||= Money.default_currency.iso_code
  end

end

