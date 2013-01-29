class AddChargesToInvoices < ActiveRecord::Migration
  def self.up
    add_column :invoices, :charge_amount_in_cents, :integer, :default => 0
    add_column :invoices, :charge_reason, :string
  end

  def self.down
    remove_column :invoices, :charge_reason
    remove_column :invoices, :charge_amount_in_cents
  end
end
