class AddAmountsWithheldToInvoices < ActiveRecord::Migration

  def up
    add_column :invoices, :amounts_withheld_in_cents, :integer
  end

  def down
    remove_column :invoices, :amounts_withheld_in_cents
  end

end
