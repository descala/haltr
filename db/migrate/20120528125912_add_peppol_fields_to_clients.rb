class AddPeppolFieldsToClients < ActiveRecord::Migration

  def self.up
    add_column :clients, :schemeid, :string
    add_column :clients, :endpointid, :string
  end

  def self.down
    remove_column :clients, :schemeid
    remove_column :clients, :endpointid
  end

end
