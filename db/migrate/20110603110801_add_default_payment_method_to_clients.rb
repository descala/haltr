class AddDefaultPaymentMethodToClients < ActiveRecord::Migration
  def self.up
    add_column :clients, :terms, :string
    add_column :clients, :payment_method, :integer
  end

  def self.down
    remove_column :clients, :terms
    remove_column :clients, :payment_method
  end
end
