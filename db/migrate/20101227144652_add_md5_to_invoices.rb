class AddMd5ToInvoices < ActiveRecord::Migration

  def self.up
    add_column :invoices, :md5, :string
  end

  def self.down
    remove_column :invoices, :md5
  end

end
