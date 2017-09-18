class AddHtmlToInvoices < ActiveRecord::Migration
  def self.up
    add_column :invoices, :html, :text
  end

  def self.down
    remove_column :invoices, :html
  end
end
