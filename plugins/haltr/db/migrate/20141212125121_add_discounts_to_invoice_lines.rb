class AddDiscountsToInvoiceLines < ActiveRecord::Migration

  def up
    add_column :invoice_lines, :discount_percent, :integer, :default => 0
    add_column :invoice_lines, :discount_text, :string
  end

  def down
    remove_column :invoice_lines, :discount_percent
    remove_column :invoice_lines, :discount_text
  end

end
