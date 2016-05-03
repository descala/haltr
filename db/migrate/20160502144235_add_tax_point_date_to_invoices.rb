class AddTaxPointDateToInvoices < ActiveRecord::Migration

  def up
    add_column :invoices, :tax_point_date, :date
  end

  def down
    remove_column :invoices, :tax_point_date
  end

end
