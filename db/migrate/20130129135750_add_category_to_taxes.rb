include Haltr::TaxHelper

class AddCategoryToTaxes < ActiveRecord::Migration

  def self.up
    # E=Exempt, Z=ZeroRated, S=Standard, H=High Rate, AA=Low Rate
    add_column :taxes, :category, :string, :default => "S"
    add_column :taxes, :comment, :string
    add_category_to_taxes
  end

  def self.down
    remove_column :taxes, :comment
    remove_column :taxes, :category
  end
end
