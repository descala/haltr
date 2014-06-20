class AddTitleToInvoices < ActiveRecord::Migration
  def change
    add_column :invoices, :title, :string
  end
end
