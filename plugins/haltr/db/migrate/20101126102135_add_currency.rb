class AddCurrency < ActiveRecord::Migration

  def self.up
    add_column :invoices, :currency, :string, :default => Money.default_currency.iso_code
    add_column :companies, :currency, :string, :default => Money.default_currency.iso_code
  end

  def self.down
    remove_column :invoices, :currency
    remove_column :companies, :currency
  end

end
