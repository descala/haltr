class AddInvoiceFormatToInvoices < ActiveRecord::Migration
  def self.up
    add_column :invoices, :invoice_format, :string
  end

  def self.down
    remove_column :invoices, :invoice_format
  end
end
