class AddAmendOfToInvoices < ActiveRecord::Migration

  def self.up
    add_column :invoices, :amend_id, :integer
  end

  def self.down
    remove_column :invoices, :amend_id
  end

end
