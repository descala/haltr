class ChangeMailCustomizationColumnsFromCompany < ActiveRecord::Migration
  def change
    rename_column :companies, :mail_customization, :invoice_mail_customization
    add_column :companies, :quote_mail_customization, :text, :default => ''
  end
end
