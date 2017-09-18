class AddIssuerTransactionReferenceToInvoiceLines < ActiveRecord::Migration

  def up
    add_column :invoice_lines, :issuer_transaction_reference, :string
  end

  def down
    remove_column :invoice_lines, :issuer_transaction_reference
  end

end
