class RmHtmlFromInvoices < ActiveRecord::Migration
  def self.up
    remove_column :invoices, :html
  end

  def self.down
    add_column :invoices, :html, :text
  end
end
