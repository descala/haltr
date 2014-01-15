class InternationalTaxcodes < ActiveRecord::Migration

  def self.up
    rename_column :companies, :taxid, :taxcode
    change_column :companies, :taxcode, :string, :limit => 20
    change_column :clients,   :taxcode, :string, :limit => 20
  end

  def self.down
    rename_column :companies, :taxcode, :taxid
    change_column :companies, :taxid, :string, :limit => 9
    change_column :clients,   :taxcode, :string, :limit => 9
  end

end
