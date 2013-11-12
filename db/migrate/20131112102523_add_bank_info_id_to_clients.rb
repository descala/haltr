class AddBankInfoIdToClients < ActiveRecord::Migration
  def self.up
    add_column :clients, :bank_info_id, :integer
    Client.all.each do |client|
      next unless [Invoice::PAYMENT_TRANSFER, Invoice::PAYMENT_DEBIT].include?(client.payment_method)
      if client.project.company.bank_infos.size == 1
        client.bank_info = client.project.company.bank_infos.first
        client.save
      end
    end
  end

  def self.down
    remove_column :clients, :bank_info_id
  end
end
