# == Schema Information
# Schema version: 20091016144057
#
# Table name: invoice_lines
#
#  id             :integer(4)      not null, primary key
#  invoice_id     :integer(4)
#  quantity       :decimal(10, 2)
#  description    :string(512)
#  price_in_cents :integer(4)
#  created_at     :datetime
#  updated_at     :datetime
#

class InvoiceLine < ActiveRecord::Base

  unloadable

  belongs_to :invoice
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

end
