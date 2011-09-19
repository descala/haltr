class AddPaymentMethodTextToInvoicesAndClients < ActiveRecord::Migration

  def self.up
    add_column :invoices, :payment_method_text, :string
    add_column :clients, :payment_method_text, :string
  end

  def self.down
    remove_column :invoices, :payment_method_text
    remove_column :clients, :payment_method_text
  end

end
