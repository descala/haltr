class AddAccountingCostToInvoices < ActiveRecord::Migration

  def self.up
    add_column :invoices, :accounting_cost, :string
  end

  def self.down
    remove_column :invoices, :accounting_cost
  end

end
