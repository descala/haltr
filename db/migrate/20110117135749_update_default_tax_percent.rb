class UpdateDefaultTaxPercent < ActiveRecord::Migration
  def self.up
    change_column_default :invoices, :tax_percent, 18
  end

  def self.down
    change_column_default :invoices, :tax_percent, 16
  end
end
