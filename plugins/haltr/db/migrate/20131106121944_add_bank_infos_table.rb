class AddBankInfosTable < ActiveRecord::Migration
  def self.up
    create_table :bank_infos do |t|
      t.string  :name
      t.string  :bank_account, :limit => 24
      t.string  :iban
      t.string  :bic
      t.integer :company_id
      t.timestamps null: false
    end
    add_column    :invoices,  :bank_info_id, :integer
    Company.all.each do |company|
      unless company.bank_account.blank? and company.iban.blank? and company.bic.blank?
        BankInfo.create!(:bank_account => company.bank_account,
                         :iban         => company.iban,
                         :bic          => company.bic,
                         :company_id   => company.id)
      end
    end rescue nil
    Invoice.where(["payment_method in (?, ?)", Invoice::PAYMENT_TRANSFER, Invoice::PAYMENT_DEBIT]).each do |invoice|
      if invoice.project.company.bank_infos.size == 1
        invoice.bank_info = invoice.client.project.company.bank_infos.first
        invoice.save
      end
    end rescue nil
    remove_column :companies, :bank_account
    remove_column :companies, :iban
    remove_column :companies, :bic
  end

  def self.down
    drop_table :bank_infos
    add_column :companies, :bank_account, :string
    add_column :companies, :iban,         :string
    add_column :companies, :bic,          :string
    remove_column :invoices, :bank_info_id
  end
end
