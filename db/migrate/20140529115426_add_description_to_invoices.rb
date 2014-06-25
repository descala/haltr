class AddDescriptionToInvoices < ActiveRecord::Migration
  def change
    add_column :invoices, :description, :text, :default => ''
  end
end
