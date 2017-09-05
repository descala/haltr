class RemoveDepartmentFromCompanies < ActiveRecord::Migration
  def change
    remove_column :companies, :department, :string
  end
end
