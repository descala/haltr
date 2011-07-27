class RemoveDefaultCountryAndCurrency < ActiveRecord::Migration

  def self.up
    change_column_default :clients,   :country,  nil
    change_column_default :companies, :country,  nil
    change_column_default :companies, :currency, nil
    change_column_default :invoices,  :currency, nil
  end

  def self.down
    change_column_default :clients,   :country,  "es"
    change_column_default :companies, :country,  "ESP"
    change_column_default :companies, :currency, "EUR"
    change_column_default :invoices,  :currency, "EUR"
  end

end
