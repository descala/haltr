class AddInvoicingPeriodFieldsToInvoiceLines < ActiveRecord::Migration

  def change
    add_column :invoice_lines, :invoicing_period_start, :date
    add_column :invoice_lines, :invoicing_period_end,   :date
  end

end
