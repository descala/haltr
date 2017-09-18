class AddSeriesCodeToInvoices < ActiveRecord::Migration

  def up
    add_column :invoices, :series_code, :string
  end

  def down
    remove_column :invoices, :series_code
  end

end
