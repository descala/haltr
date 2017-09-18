class ModifyQuantity < ActiveRecord::Migration
  def self.up
    change_column :invoice_lines, :quantity, :float
  end

  def self.down
    change_column :invoice_lines, :quantity, :integer
  end
end
