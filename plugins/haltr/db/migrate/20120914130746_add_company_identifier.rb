class AddCompanyIdentifier < ActiveRecord::Migration

  def self.up
    add_column :clients,   :company_identifier, :string
    add_column :companies, :company_identifier, :string
  end

  def self.down
    remove_column :clients,   :company_identifier
    remove_column :companies, :company_identifier
  end

end
