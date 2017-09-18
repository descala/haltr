class RemoveSubtotalInCentsFromInvoices < ActiveRecord::Migration

  def self.up
    remove_column :invoices, :subtotal_in_cents
  end

  def self.down
    add_column :invoices, :subtotal_in_cents, :integer
  end

end
