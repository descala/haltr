class AddPeppolFieldsToCompanies < ActiveRecord::Migration

  def self.up
    add_column :companies, :schemeid, :string
    add_column :companies, :endpointid, :string
  end

  def self.down
    remove_column :companies, :schemeid
    remove_column :companies, :endpointid
  end

end
