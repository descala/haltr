class AddClientCompanyRelation < ActiveRecord::Migration
  def self.up
    add_column :clients, :company_id, :integer
    add_column :companies, :public, :boolean, :default => false
    add_column :companies, :invoice_format, :string
  end

  def self.down
    remove_column :clients, :company_id
    remove_column :companies, :public
    remove_column :companies, :invoice_format
  end
end
