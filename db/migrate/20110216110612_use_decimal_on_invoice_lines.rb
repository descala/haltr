class UseDecimalOnInvoiceLines < ActiveRecord::Migration
  def self.up
    # InvoiceLine.all.collect {|i| i.price = (i.price/100).to_s ; i.save(false) }
    # InvoiceLine.all.collect {|i| i.quantity = i.quantity.round(2).to_s ; i.save(false) }
    change_column :invoice_lines, :quantity, :decimal, :precision => 18, :scale => 9
    change_column :invoice_lines, :price_in_cents, :decimal, :precision => 18, :scale => 9
    rename_column :invoice_lines, :price_in_cents, :price
  end

  def self.down
    rename_column :invoice_lines, :price, :price_in_cents
    change_column :invoice_lines, :quantity, :float
    change_column :invoice_lines, :price_in_cents, :integer
  end
end
