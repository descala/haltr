class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|
      t.column :name, :string
      t.column :user_id, :integer
      t.column :invoice_id, :integer
      t.column :info, :text
      t.column :md5, :string
      t.column :filename, :string
      t.timestamps null: false
    end
  end

  def self.down
    drop_table :events
  end
end
