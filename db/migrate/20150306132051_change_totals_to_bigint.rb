class ChangeTotalsToBigint < ActiveRecord::Migration
  def up
    change_column :invoices, :total_in_cents, :bigint
    change_column :invoices, :import_in_cents, :bigint
    change_column :invoices, :charge_amount_in_cents, :bigint
    change_column :invoices, :payments_on_account_in_cents, :bigint
    change_column :payments, :amount_in_cents, :bigint
  end

  def down
    change_column :invoices, :total_in_cents, :integer
    change_column :invoices, :import_in_cents, :integer
    change_column :invoices, :charge_amount_in_cents, :integer
    change_column :invoices, :payments_on_account_in_cents, :integer
    change_column :payments, :amount_in_cents, :integer
  end
end
