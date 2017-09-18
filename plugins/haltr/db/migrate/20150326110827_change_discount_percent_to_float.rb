class ChangeDiscountPercentToFloat < ActiveRecord::Migration

  def up
    change_column :invoices,      :discount_percent, :decimal, precision: 5, scale: 2
    change_column :invoice_lines, :discount_percent, :decimal, precision: 5, scale: 2
  end

  def down
    change_column :invoices,      :discount_percent, :integer
    change_column :invoice_lines, :discount_percent, :integer
  end

end
