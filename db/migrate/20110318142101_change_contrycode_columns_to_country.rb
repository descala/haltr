class ChangeContrycodeColumnsToCountry < ActiveRecord::Migration
  def self.up
    rename_column :clients, :countrycode, :country
    rename_column :companies, :countrycode, :country
    Client.all.each do |client|
      begin
        client.country = SunDawg::CountryIsoTranslater.translate_standard(client.country,"alpha3","alpha2").downcase rescue "es"
        client.save(:validate=>false)
      rescue
      end
    end
    Company.all.each do |company|
      begin
        company.country = SunDawg::CountryIsoTranslater.translate_standard(company.country,"alpha3","alpha2").downcase rescue "es"
        company.save(:validate=>false)
      rescue
      end
    end
  end

  def self.down
    rename_column :clients, :country, :countrycode
    rename_column :companies, :country, :countrycode
    Client.all.each do |client|
    end
    Company.all.each do |company|
    end
    Client.all.each do |client|
      begin
        client.country = SunDawg::CountryIsoTranslater.translate_standard(client.country.upcase,"alpha2","alpha3") rescue "ESP"
        client.save(:validate=>false)
      rescue
      end
    end
    Company.all.each do |company|
      begin
        company.country = SunDawg::CountryIsoTranslater.translate_standard(company.country.upcase,"alpha2","alpha3") rescue "ESP"
        company.save(:validate=>false)
      rescue
      end
    end
  end
end
