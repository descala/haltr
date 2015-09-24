class AddPartiallyAmendedIdToInvoices < ActiveRecord::Migration

  def up
    add_column :invoices, :partially_amended_id, :integer
    add_column :invoices, :amend_reason_code, :string, default: '15'
  end

  def down
    remove_column :invoices, :partially_amended_id
    remove_column :invoices, :amend_reason_code
  end

end
