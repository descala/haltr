class AddLineDiscountsAsImportsToCompanies < ActiveRecord::Migration

  def up
    add_column :companies, :line_discounts_as_imports, :boolean, default: false
  end

  def down
    remove_column :companies, :line_discounts_as_imports
  end

end
