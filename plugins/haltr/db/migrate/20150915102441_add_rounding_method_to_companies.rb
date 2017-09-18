class AddRoundingMethodToCompanies < ActiveRecord::Migration

  def up
    add_column :companies, :rounding_method, :string, default: :half_up
    add_column :companies, :round_before_sum, :boolean, default: false
  end

  def down
    remove_column :companies, :rounding_method
    remove_column :companies, :round_before_sum
  end

end
