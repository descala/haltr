class AddPositionToInvoiceLines < ActiveRecord::Migration

  def change
    add_column :invoice_lines, :position, :integer
  end

end
