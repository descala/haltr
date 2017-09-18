class TaxPercent < ActiveRecord::Migration
  def self.up
    add_column :invoices, :tax_percent, :integer, :default => 16
  end

  def self.down
    remove_column :invoices, :tax_percent
  end
end
