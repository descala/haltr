class AddIbanAndBic < ActiveRecord::Migration

  def self.up
    add_column :clients,   :iban, :string
    add_column :clients,   :bic,  :string
    add_column :companies, :iban, :string
    add_column :companies, :bic,  :string
  end

  def self.down
    change_column_default :clients, :country, "ESP"
  end

end
