class AddMissingIndexes < ActiveRecord::Migration
  def self.up
    add_index :companies, :project_id
    add_index :companies, :taxcode
    add_index :bank_infos, :company_id
    add_index :people, :client_id
    add_index :people, :send_invoices_by_mail
    add_index :invoices, :invoice_template_id
    add_index :invoices, :amend_id
    add_index :invoices, :bank_info_id
    add_index :payments, :invoice_id
    add_index :payments, :project_id
    add_index :events, :invoice_id
    add_index :events, :user_id
    add_index :clients, :project_id
    add_index :clients, :company_id
    add_index :clients, :bank_info_id
    add_index :clients, :taxcode
    add_index :clients, :hashid
  end
  
  def self.down
    remove_index :companies, :project_id
    remove_index :companies, :taxcode
    remove_index :bank_infos, :company_id
    remove_index :people, :client_id
    remove_index :people, :send_invoices_by_mail
    remove_index :invoices, :invoice_template_id
    remove_index :invoices, :amend_id
    remove_index :invoices, :bank_info_id
    remove_index :payments, :invoice_id
    remove_index :payments, :project_id
    remove_index :events, :invoice_id
    remove_index :events, :user_id
    remove_index :clients, :project_id
    remove_index :clients, :company_id
    remove_index :clients, :bank_info_id
    remove_index :clients, :taxcode
    remove_index :clients, :hashid
  end
end
