class RemoveColumnsFromInvoices < ActiveRecord::Migration

  def self.up
    remove_column :invoices, :b2brouter_url
    remove_column :invoices, :filename
    remove_column :invoices, :channel
    remove_column :invoices, :md5
  end

  def self.down
    add_column :invoices, :b2brouter_url, :string
    add_column :invoices, :filename,      :string
    add_column :invoices, :channel,       :string
    add_column :invoices, :md5,           :string
  end

end
