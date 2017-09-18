class RenameClientsAddress1ToAddress < ActiveRecord::Migration
  def self.up
    rename_column :clients, :address1, :address
  end

  def self.down
    rename_column :clients, :address, :address1
  end
end
