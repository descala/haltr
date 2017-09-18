class AddWebsiteToClients < ActiveRecord::Migration
  def self.up
    add_column :clients, :website, :string
  end

  def self.down
    remove_column :clients, :website
  end
end
