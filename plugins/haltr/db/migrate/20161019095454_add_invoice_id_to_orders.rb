class AddInvoiceIdToOrders < ActiveRecord::Migration

  def up
    add_column :orders, :invoice_id, :integer
  end

  def down
    remove_column :orders, :invoice_id
  end

end
