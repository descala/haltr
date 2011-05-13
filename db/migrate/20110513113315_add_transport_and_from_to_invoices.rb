class AddTransportAndFromToInvoices < ActiveRecord::Migration
  def self.up
    add_column :invoices, :transport, :string
    add_column :invoices, :from,      :string
  end

  def self.down
    remove_column :invoices, :transport
    remove_column :invoices, :from
  end
end
