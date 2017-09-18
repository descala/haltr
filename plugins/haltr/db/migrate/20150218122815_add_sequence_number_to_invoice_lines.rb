class AddSequenceNumberToInvoiceLines < ActiveRecord::Migration

  def change
    add_column :invoice_lines, :sequence_number, :string
  end

end
