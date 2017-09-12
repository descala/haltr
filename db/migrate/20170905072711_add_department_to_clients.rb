class AddDepartmentToClients < ActiveRecord::Migration
  def change
    add_column :clients, :department, :string
  end
end
