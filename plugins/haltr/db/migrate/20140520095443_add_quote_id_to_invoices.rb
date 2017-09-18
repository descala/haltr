class AddQuoteIdToInvoices < ActiveRecord::Migration
  def change
    add_column :invoices, :quote_id, :integer
  end
end
