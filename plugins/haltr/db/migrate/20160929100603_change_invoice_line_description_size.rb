class ChangeInvoiceLineDescriptionSize < ActiveRecord::Migration
  def up
    change_column :invoice_lines, :description, :string, limit: 2500
  end

  def down
    change_column :invoice_lines, :description, :string, limit: 512
  end
end
