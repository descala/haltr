class ChangeInvoicesTaxPercentType < ActiveRecord::Migration
  def self.up
    change_column :invoices, :tax_percent, :float
  end

  def self.down
    change_column :invoices, :tax_percent, :int
  end
end
