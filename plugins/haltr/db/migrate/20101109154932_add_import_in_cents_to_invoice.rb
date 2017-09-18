class AddImportInCentsToInvoice < ActiveRecord::Migration
  def self.up
    add_column :invoices, :import_in_cents, :integer
    InvoiceDocument.all.each {|i| i.save!}
  end

  def self.down
    remove_column :invoices, :import_in_cents
  end
end
