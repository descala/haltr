class AddStateToOrders < ActiveRecord::Migration

  def change
    add_column :orders, :state, :string, default: 'received'
  end

end
