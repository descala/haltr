class AddColumnsToInvoices < ActiveRecord::Migration
  def self.up
    add_column :invoices, :subtotal_in_cents, :integer
    add_column :invoices, :withholding_tax_in_cents, :integer
  end

  def self.down
    remove_column :invoices, :subtotal_in_cents
    remove_column :invoices, :withholding_tax_in_cents
  end
end
