class AddMailCustomizationColumnsToCompany < ActiveRecord::Migration
  def change
    add_column :companies, :mail_subject, :string, :default => ''
    add_column :companies, :mail_body, :string, :default => ''
  end
end
