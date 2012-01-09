class AddSendInvoicesByMailToPeople < ActiveRecord::Migration

  def self.up
    add_column :people, :send_invoices_by_mail, :boolean, :default => true
  end

  def self.down
    remove_column :people, :send_invoices_by_mail
  end

end
