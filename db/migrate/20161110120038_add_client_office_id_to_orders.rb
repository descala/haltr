class AddClientOfficeIdToOrders < ActiveRecord::Migration

  def up
    add_column :orders, :client_office_id, :integer
  end

  def down
    remove_column :orders, :client_office_id
  end

end
