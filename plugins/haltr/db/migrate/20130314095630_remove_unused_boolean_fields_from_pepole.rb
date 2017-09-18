class RemoveUnusedBooleanFieldsFromPepole < ActiveRecord::Migration
  def self.up
    remove_column :people, "invoice_recipient"
    remove_column :people, "report_recipient"
  end

  def self.down
    add_column :people, "invoice_recipient", :boolean, :default => false
    add_column :people, "report_recipient",  :boolean, :default => false
  end
end
