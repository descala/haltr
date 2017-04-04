class AddImportToTaxes < ActiveRecord::Migration

  def change
    add_column :taxes, :import, :decimal, precision: 18, scale: 9
  end

end
