class ChangeContrycodeColumnsToCountry < ActiveRecord::Migration
  def self.up
    rename_column :clients, :countrycode, :country
    rename_column :companies, :countrycode, :country
    Client.all.each do |client|
      begin
        client.country = SunDawg::CountryIsoTranslater.translate_standard(client.country,"alpha3","alpha2")
        client.save(false)
      rescue
      end
    end
    Company.all.each do |company|
      begin
        company.country = SunDawg::CountryIsoTranslater.translate_standard(company.country,"alpha3","alpha2")
        company.save(false)
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
        client.country = SunDawg::CountryIsoTranslater.translate_standard(client.country,"alpha2","alpha3")
        client.save(false)
      rescue
      end
    end
    Company.all.each do |company|
      begin
        company.country = SunDawg::CountryIsoTranslater.translate_standard(company.country,"alpha2","alpha3")
        company.save(false)
      rescue
      end
    end
  end
end
