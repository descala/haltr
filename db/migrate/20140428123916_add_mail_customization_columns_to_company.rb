class AddMailCustomizationColumnsToCompany < ActiveRecord::Migration
  def change
    add_column :companies, :mail_customization, :text, :default => ''
  end
end
