class AddAmendedNumberToInvoices < ActiveRecord::Migration

  def up
    add_column :invoices, :amended_number, :string
  end

  def down
    remove_column :invoices, :amended_number
  end

end
