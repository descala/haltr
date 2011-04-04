class AddUnitToInvoiceLines < ActiveRecord::Migration
  def self.up
    add_column :invoice_lines, :unit, :integer, :default => 1
  end

  def self.down
    remove_column :invoice_lines, :unit
  end
end
