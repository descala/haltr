class AddCompanies < ActiveRecord::Migration

  def self.up
    create_table "companies" do |t|
      t.integer "project_id"
      t.string  "name"
      t.string  "taxid", :limit => 9
      t.string  "address"
      t.string  "locality"
      t.string  "postal_code"
      t.string  "region"
      t.string  "website"
      t.string  "email"
      t.string  "bank_account", :limit => 24
      t.string  "logo_url"
      t.timestamps null: false
    end
  end

  def self.down
    drop_table :companies
  end

end
