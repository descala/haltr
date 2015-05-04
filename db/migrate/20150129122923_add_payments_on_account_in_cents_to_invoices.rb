class AddPaymentsOnAccountInCentsToInvoices < ActiveRecord::Migration

  def up
    add_column :invoices, :payments_on_account_in_cents, :integer, :default => 0
  end

  def down
    remove_column :invoices, :payments_on_account_in_cents
  end

end
