class AddTaxes < ActiveRecord::Migration

  def self.up
    create_table :taxes do |t|
      t.integer :company_id
      t.string  :name
      t.float   :percent
    end
    create_table :invoices_taxes, :id => false do |t|
      t.integer :invoice_id
      t.integer :tax_id
    end
    add_index(:taxes, [:company_id, :name, :percent], :unique => true)
    add_index(:invoices_taxes, [:invoice_id, :tax_id], :unique => true)
  end

  def self.down
    drop_table :taxes
    drop_table :invoices_taxes
  end

end
