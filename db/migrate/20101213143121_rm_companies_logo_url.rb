class RmCompaniesLogoUrl < ActiveRecord::Migration

  def self.up
    remove_column :companies, :logo_url
  end

  def self.down
    add_column :companies, :logo_url, :string
  end

end
