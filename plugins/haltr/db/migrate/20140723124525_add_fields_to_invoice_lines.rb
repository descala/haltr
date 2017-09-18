class AddFieldsToInvoiceLines < ActiveRecord::Migration

  def up
    add_column :invoice_lines, :article_code, :string
    add_column :invoice_lines, :notes, :text
  end

  def down
    remove_column :invoice_lines, :article_code
    remove_column :invoice_lines, :notes
  end

end
