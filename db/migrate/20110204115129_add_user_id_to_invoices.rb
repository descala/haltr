class AddUserIdToInvoices < ActiveRecord::Migration
  def self.up
    # Invoice.all.collect {|i| i.user_id=i.client.project.users.collect {|u| u.id unless u.id == 1}.compact.first ; i.save }
    add_column :invoices, :user_id, :integer
  end

  def self.down
    remove_column :invoices, :user_id
  end
end
