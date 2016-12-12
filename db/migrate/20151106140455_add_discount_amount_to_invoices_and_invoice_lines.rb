class AddDiscountAmountToInvoicesAndInvoiceLines < ActiveRecord::Migration

  def up
    add_column :invoices,      :discount_amount, :decimal, precision: 18, scale: 9
    add_column :invoice_lines, :discount_amount, :decimal, precision: 18, scale: 9
  end

  def down
    remove_column :invoices,      :discount_amount
    remove_column :invoice_lines, :discount_amount
  end

end
