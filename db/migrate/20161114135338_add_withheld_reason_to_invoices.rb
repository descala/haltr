class AddWithheldReasonToInvoices < ActiveRecord::Migration

  def change
    add_column :invoices, :amounts_withheld_reason, :string
  end

end
