class AddSmtpSettingsToCompany < ActiveRecord::Migration

  def up
    add_column :companies, :smtp_host,     :string
    add_column :companies, :smtp_port,     :integer, default: 25
    add_column :companies, :smtp_ssl,      :boolean, default: true
    add_column :companies, :smtp_from,     :string
    add_column :companies, :smtp_username, :string
    add_column :companies, :smtp_password, :string
  end

  def down
    remove_column :companies, :smtp_host
    remove_column :companies, :smtp_port
    remove_column :companies, :smtp_ssl
    remove_column :companies, :smtp_from
    remove_column :companies, :smtp_username
    remove_column :companies, :smtp_password
  end

end
