class CreateDir3s < ActiveRecord::Migration

  def up
    create_table :dir3s do |t|
      t.string :taxcode
      t.string :organ_gestor_id
      t.string :unitat_tramitadora_id
      t.string :oficina_contable_id
    end
    create_table :dir3_entities do |t|
      t.string :name
      t.string :code
      t.string :address
      t.string :postalcode
      t.string :city
      t.string :province
      t.string :country
      t.string :tipus
    end
    add_column :invoices, :dir3_id, :integer
  end

  def down
    drop_table :dir3s
    drop_table :dir3_entities
    remove_column :invoices, :dir3_id
  end

end
