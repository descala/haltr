class AddFileReferenceToInvoices < ActiveRecord::Migration

  def up
    add_column :invoices, :file_reference, :string
  end

  def down
    remove_column :invoices, :file_reference
  end

end
