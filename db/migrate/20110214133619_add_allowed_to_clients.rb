class AddAllowedToClients < ActiveRecord::Migration
  def self.up
    add_column :clients, :allowed, :boolean, :default => nil
  end

  def self.down
    remove_column :clients, :allowed
  end
end
