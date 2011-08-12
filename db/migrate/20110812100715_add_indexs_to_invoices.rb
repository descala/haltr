class AddIndexsToInvoices < ActiveRecord::Migration
  def self.up
    add_index(:invoices, :client_id)
    add_index(:invoices, :project_id)
    add_index(:invoices, :date)
  end

  def self.down
    remove_index(:invoices, :client_id)
    remove_index(:invoices, :project_id)
    remove_index(:invoices, :date)
  end
end
