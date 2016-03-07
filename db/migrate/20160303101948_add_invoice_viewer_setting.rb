class AddInvoiceViewerSetting < ActiveRecord::Migration
  def change
    add_column :companies, :invoice_viewer, :string
  end
end
