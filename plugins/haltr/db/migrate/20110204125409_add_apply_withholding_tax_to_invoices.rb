class AddApplyWithholdingTaxToInvoices < ActiveRecord::Migration
  def self.up
    add_column :invoices, :apply_withholding_tax, :boolean, :default => false
  end

  def self.down
    remove_column :invoices, :apply_withholding_tax
  end
end
