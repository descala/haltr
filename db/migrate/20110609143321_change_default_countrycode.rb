class ChangeDefaultCountrycode < ActiveRecord::Migration

  def self.up
    change_column_default :clients, :countrycode, "es"
  end

  def self.down
    change_column_default :clients, :countrycode, "ESP"
  end

end
