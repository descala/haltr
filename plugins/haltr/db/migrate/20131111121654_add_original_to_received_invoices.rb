class AddOriginalToReceivedInvoices < ActiveRecord::Migration
  def self.up
    add_column :invoices, :md5, :string
    add_column :invoices, :file_name, :string
    add_column :invoices, :original, :text, :limit => 16777215
  end

  def self.down
    remove_column :invoices, :md5
    remove_column :invoices, :file_name
    remove_column :invoices, :original
  end
end
