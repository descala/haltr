class AddFilenameToInvoices < ActiveRecord::Migration

  def self.up
    add_column :invoices, :filename, :string
  end

  def self.down
    remove_column :invoices, :filename
  end

end
