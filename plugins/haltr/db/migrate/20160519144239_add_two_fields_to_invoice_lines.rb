class AddTwoFieldsToInvoiceLines < ActiveRecord::Migration

  def up
    add_column :invoice_lines, :receiver_contract_reference, :string
    add_column :invoice_lines, :file_reference, :string
  end

  def down
    remove_column :invoice_lines, :receiver_contract_reference
    remove_column :invoice_lines, :file_reference
  end

end
