class AddHashToClients < ActiveRecord::Migration
  def self.up
    add_column :clients, :hashid, :string
  end

  def self.down
    remove_column :clients, :hashid
  end
end
