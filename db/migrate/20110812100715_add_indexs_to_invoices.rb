class AddIndexsToInvoices < ActiveRecord::Migration
  def self.up
    add_index(:invoices, :client_id)
    add_index(:invoices, :project_id)
    add_index(:invoices, :date)
    add_index(:invoices, :type)
    add_index(:invoices, :number)
    add_index(:invoice_lines, :invoice_id)
  end

  def self.down
    remove_index(:invoices, :client_id)
    remove_index(:invoices, :project_id)
    remove_index(:invoices, :date)
    remove_index(:invoices, :type)
    remove_index(:invoices, :number)
    remove_index(:invoice_lines, :invoice_id)
  end
end
