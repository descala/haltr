class UpdateInvoiceDocumentType < ActiveRecord::Migration
  def self.up
    execute "UPDATE invoices SET type='IssuedInvoice' WHERE type='InvoiceDocument'"
  end

  def self.down
    execute "UPDATE invoices SET type='InvoiceDocument' WHERE type='IssuedInvoice'"
  end
end
