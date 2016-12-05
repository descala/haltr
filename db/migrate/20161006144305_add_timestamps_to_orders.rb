class AddTimestampsToOrders < ActiveRecord::Migration

  def up
    add_column :orders, :created_at, :datetime
    add_column :orders, :updated_at, :datetime
    Order.update_all created_at: Time.now
    Order.update_all updated_at: Time.now
  end

  def down
    remove_column :orders, :created_at
    remove_column :orders, :updated_at
  end

end
