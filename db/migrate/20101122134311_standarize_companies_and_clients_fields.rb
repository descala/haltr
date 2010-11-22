class StandarizeCompaniesAndClientsFields < ActiveRecord::Migration

  def self.up
    rename_column :companies, :postal_code, :postalcode
    rename_column :companies, :locality, :city
    rename_column :companies, :region, :province
  end

  def self.down
    rename_column :companies, :postalcode, :postal_code
    rename_column :companies, :city, :locality
    rename_column :companies, :province, :region
  end

end
