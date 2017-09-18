# encoding: utf-8

class AddCountrycode < ActiveRecord::Migration

  def self.up
    add_column :companies, :countrycode, :string, :default => "ESP"
    rename_column :clients, :country, :countrycode
    change_column_default :clients, :countrycode, "ESP"
    change_column_default :clients, :countrycode, "ESP"
    Client.all.each { |c|
      c.countrycode = "ESP" if c.countrycode == "España"
      c.save
    }
  end

  def self.down
    remove_column :companies, :countrycode
    rename_column :clients, :countrycode, :country
    change_column_default :clients, :country, "españa"
    Client.all.each { |c|
      c.country = "España" if c.country == "ESP"
      c.save
    }
  end

end
