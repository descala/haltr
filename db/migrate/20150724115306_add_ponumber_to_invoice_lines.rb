class AddPonumberToInvoiceLines < ActiveRecord::Migration

  def up
    add_column :invoice_lines, :ponumber, :string
  end

  def down
    remove_column :invoice_lines, :ponumber
  end

end
