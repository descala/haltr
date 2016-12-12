class CreateExternalCompanies < ActiveRecord::Migration

  def up
    create_table :external_companies do |t|
      t.string  'name'
      t.string  'taxcode'
      t.string  'address'
      t.string  'city'
      t.string  'postalcode'
      t.string  'province'
      t.string  'website'
      t.string  'email'
      t.string  'country'
      t.string  'currency'
      t.string  'public', :default => 'public'
      t.string  'invoice_format'
      t.string  'schemeid'
      t.string  'endpointid'
      t.string  'company_identifier'
      t.string  'persontype', :default => 'J'
      t.timestamps
    end

    add_column :clients, :company_type, :string
  end

  def down
    drop_table :external_companies
    remove_column :clients, :company_type
  end

end
