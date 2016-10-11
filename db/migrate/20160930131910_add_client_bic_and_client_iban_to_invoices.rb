class AddClientBicAndClientIbanToInvoices < ActiveRecord::Migration

  def up
    add_column :invoices, :client_iban, :string
    add_column :invoices, :client_bic, :string
  end

  def down
    remove_column :invoices, :client_iban
    remove_column :invoices, :client_bic
  end

end
