class RemoveDraftFieldFromInvoice < ActiveRecord::Migration

  def self.up
    remove_column :invoices, :draft
  end

  def self.down
    add_column :invoices, :draft, :boolean
  end

end
