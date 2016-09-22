class AddCreatedFromInvoiceIdToInvoices < ActiveRecord::Migration

  def up
    add_column :invoices, :created_from_invoice_id, :integer
  end

  def down
    remove_column :invoices, :created_from_invoice_id
  end

end
