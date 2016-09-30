class AddOrders < ActiveRecord::Migration

  def up
    create_table "orders" do |t|
      t.integer "project_id"
      t.string  "num_pedido"
      t.string  "fecha_documento"
      t.string  "lugar_entrega"
      t.string  "fecha_pedido"
      t.string  "fecha_entrega"
      t.text    "original"
      t.string  "filename"
      t.string  "type"
      t.integer "client_id"
      t.integer "comments_count"
    end
    add_column :events, :order_id, :integer
  end

  def down
    drop_table :orders
  end

end
