class CreateClientOffices < ActiveRecord::Migration

  def change
    create_table :client_offices do |t|
      t.integer :client_id
      t.string  :name
      t.string  :address
      t.string  :address2
      t.string  :city
      t.string  :province
      t.string  :postalcode
      t.string  :country
      t.string  :email

      t.timestamps
    end
    add_index :client_offices, :client_id
  end

end
