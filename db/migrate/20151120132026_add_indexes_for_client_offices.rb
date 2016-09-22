class AddIndexesForClientOffices < ActiveRecord::Migration

  def up
    add_index :invoices, :client_office_id
  end

  def down
    remove_index :invoices, :client_office_id
  end

end
