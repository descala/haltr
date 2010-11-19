class AddColumnsToClients < ActiveRecord::Migration

  def self.up
    add_column :clients, :email, :string
    add_column :clients, :language, :string
    add_column :clients, :currency, :string
    add_column :clients, :invoice_format, :string
  end

  def self.down
    remove_column :clients, :email
    remove_column :clients, :language
    remove_column :clients, :currency
    remove_column :clients, :invoice_format
  end

end
