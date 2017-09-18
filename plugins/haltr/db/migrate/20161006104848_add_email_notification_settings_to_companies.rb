class AddEmailNotificationSettingsToCompanies < ActiveRecord::Migration

  def up
    add_column :companies, :invoice_notifications, :boolean, default: false
    add_column :companies, :order_notifications,   :boolean, default: false
  end

  def down
    remove_column :companies, :invoice_notifications
    remove_column :companies, :order_notifications
  end

end
