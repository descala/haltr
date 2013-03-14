class RemoveUnusedBooleanFieldsFromPepole < ActiveRecord::Migration
  def self.up
    remove_column :people, "invoice_recipient"
    remove_column :people, "report_recipient"
  end

  def self.down
    boolean :people, "invoice_recipient", :default => false
    boolean :people, "report_recipient",  :default => false
  end
end
