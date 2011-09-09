class AddTaxes < ActiveRecord::Migration

  def self.up
    create_table :taxes do |t|
      t.integer :company_id
      t.integer :invoice_line_id
      t.string  :name
      t.float   :percent
    end
    add_index(:taxes, :company_id)
    add_index(:taxes, :invoice_line_id)
  end

  def self.down
    drop_table :taxes
  end

end
