class ChangeDefaultCountrycode < ActiveRecord::Migration

  def self.up
    change_column_default :clients, :country, "es"
  end

  def self.down
    change_column_default :clients, :country, "ESP"
  end

end
