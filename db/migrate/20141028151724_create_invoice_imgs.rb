class CreateInvoiceImgs < ActiveRecord::Migration
  def change
    create_table :invoice_imgs do |t|
      t.integer :invoice_id
      t.text :img, limit: 16777215
      t.text :data
      t.timestamps
    end
  end
end
