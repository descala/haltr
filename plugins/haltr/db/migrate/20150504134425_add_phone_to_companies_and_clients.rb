class AddPhoneToCompaniesAndClients < ActiveRecord::Migration

  def up
    add_column :companies, :phone, :string
    add_column :clients,   :phone, :string
  end

  def down
    remove_column :companies, :phone
    remove_column :clients,   :phone
  end

end
