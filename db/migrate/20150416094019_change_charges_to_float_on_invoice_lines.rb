class ChangeChargesToFloatOnInvoiceLines < ActiveRecord::Migration

  def up
    change_column :invoice_lines, :charge, :decimal, precision: 18, scale: 9
  end

  def down
    change_column :invoice_lines, :charge, :integer
  end

end
