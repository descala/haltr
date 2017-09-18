class RemoveTypeFromOrders < ActiveRecord::Migration

  def up
    remove_column :orders, :type
  end

  def down
    add_column :orders, :type, :string
  end

end
