class AddClientOfficeIdToInvoices < ActiveRecord::Migration

  def up
    add_column :invoices, :client_office_id, :integer
  end

  def down
    remove_column :invoices, :client_office_id
  end

end
