class AddImapSettingsToCompanies < ActiveRecord::Migration
  def self.up
    add_column :companies, :imap_host, :string
    add_column :companies, :imap_port, :integer, :default => 143
    add_column :companies, :imap_ssl, :boolean, :default => false
    add_column :companies, :imap_username, :string
    add_column :companies, :imap_password, :string
    add_column :companies, :imap_from, :string

  end

  def self.down
    remove_column :companies, :imap_password
    remove_column :companies, :imap_username
    remove_column :companies, :imap_ssl
    remove_column :companies, :imap_port
    remove_column :companies, :imap_host
    remove_column :companies, :imap_from
  end
end
