class AddWithholdingTaxToCompanies < ActiveRecord::Migration

  def self.up
    add_column :companies, :withholding_tax_name, :string
    add_column :companies, :withholding_tax_percent, :integer, :default => 0
  end

  def self.down
    remove_column :companies, :withholding_tax_name
    remove_column :companies, :withholding_tax_percent
  end

end
