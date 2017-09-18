class InvoiceRelationWithProjectInsteadOfUser < ActiveRecord::Migration
  def self.up
    # Invoice.all.collect {|i| i.project_id=i.client.project_id ; i.save }
    add_column :invoices, :project_id, :integer
    remove_column :invoices, :user_id
  end

  def self.down
    add_column :invoices, :user_id, :integer
    remove_column :invoices, :project_id
  end
end
