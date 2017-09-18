class AddDeliveryNoteNumberToInvoiceLines < ActiveRecord::Migration

  def up
    add_column :invoice_lines, :delivery_note_number, :string
  end

  def down
    remove_column :invoice_lines, :delivery_note_number
  end

end
