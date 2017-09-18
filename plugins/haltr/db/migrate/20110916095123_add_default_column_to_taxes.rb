class AddDefaultColumnToTaxes < ActiveRecord::Migration

  def self.up
    add_column :taxes, :default, :boolean
  end

  def self.down
    remove_column :taxes, :default
  end

end
