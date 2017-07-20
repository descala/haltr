class AddEpriorFieldsToClients < ActiveRecord::Migration

  def self.up
    add_column :clients, :eprior_schemeid, :string
    add_column :clients, :eprior_endpointid, :string
  end

  def self.down
    remove_column :clients, :eprior_schemeid
    remove_column :clients, :eprior_endpointid
  end

end