class AddEmailCustomizationToCompanies < ActiveRecord::Migration

  def change
    add_column :companies, :email_customization, :boolean, default: false
  end

end
