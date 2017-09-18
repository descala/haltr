class AddDepartmentToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :department, :string
  end
end
