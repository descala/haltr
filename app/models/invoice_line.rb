class InvoiceLine < ActiveRecord::Base

  unloadable

  belongs_to :invoice, :autosave => true
  validates_presence_of :description
  validates_numericality_of :quantity, :price_in_cents

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
