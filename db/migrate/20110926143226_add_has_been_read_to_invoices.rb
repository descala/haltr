class AddHasBeenReadToInvoices < ActiveRecord::Migration

  def self.up
    add_column :invoices, :has_been_read, :boolean, :default => true
  end

  def self.down
    remove_column :invoices, :has_been_read
  end

end
