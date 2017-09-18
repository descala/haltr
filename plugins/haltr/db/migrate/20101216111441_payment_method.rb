class PaymentMethod < ActiveRecord::Migration

  def self.up
    add_column :invoices, :payment_method, :integer
    Invoice.all.each do |i|
      if i.use_bank_account and i.client and !i.client.bank_account.blank?
        i.payment_method = 2
      elsif !i.use_bank_account and i.company and !i.company.bank_account.blank?
        i.payment_method = 4
      else
        i.payment_method = 1
      end
      i.save(:validate=>false)
    end
    remove_column :invoices, :use_bank_account
  end

  def self.down
    add_column :invoices, :use_bank_account, :boolean
    remove_column :invoices, :payment_method
  end

end
