class AddCompanyOffices < ActiveRecord::Migration

  def change
    create_table :company_offices do |t|
      t.string :address
      t.string :city
      t.string :postalcode
      t.string :province
      t.string :country
      t.references :company, index: true, foreign_key: true
      t.timestamps null: false
    end
    add_column :invoices, :company_office_id, :integer
    add_index :invoices, :company_office_id
  end

end
