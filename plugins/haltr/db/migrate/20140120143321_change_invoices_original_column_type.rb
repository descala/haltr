class ChangeInvoicesOriginalColumnType < ActiveRecord::Migration
  def self.up
    change_column :invoices, :original, :text, :limit => 16777215
  end

  def self.down
    change_column :invoices, :original, :text, :limit => 65535
  end
end
