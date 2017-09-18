class AddChargesToInvoiceLines < ActiveRecord::Migration

  def up
    add_column :invoice_lines, :charge, :integer, :default => 0
    add_column :invoice_lines, :charge_reason, :string
  end

  def down
    remove_column :invoice_lines, :charge
    remove_column :invoice_lines, :charge_reason
  end

end
