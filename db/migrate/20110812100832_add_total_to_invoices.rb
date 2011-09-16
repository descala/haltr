class AddTotalToInvoices < ActiveRecord::Migration

  def self.up
    add_column :invoices, :total_in_cents, :integer
  end

  def self.down
    remove_column :invoices, :total_in_cents
  end

end
