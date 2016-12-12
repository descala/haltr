class AddInvoicingPeriodToInvoices < ActiveRecord::Migration

  def up
    add_column :invoices, :invoicing_period_start, :date
    add_column :invoices, :invoicing_period_end,   :date
  end

  def down
    remove_column :invoices, :invoicing_period_start
    remove_column :invoices, :invoicing_period_end
  end

end
