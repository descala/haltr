class HasBeenReadChangeDefaultValue < ActiveRecord::Migration
  def self.up
    change_column :invoices, :has_been_read, :boolean, :default => false
  end

  def self.down
    change_column :invoices, :has_been_read, :boolean, :default => true
  end
end
