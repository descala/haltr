class AddClientEmailOverrideToInvoice < ActiveRecord::Migration
  def change
    add_column :invoices, :client_email_override, :string
  end
end
