class AddBankInfoIdToClients < ActiveRecord::Migration
  def self.up
    add_column :clients, :bank_info_id, :integer
  end

  def self.down
    remove_column :clients, :bank_info_id
  end
end
