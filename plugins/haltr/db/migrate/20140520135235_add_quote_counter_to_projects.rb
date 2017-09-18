class AddQuoteCounterToProjects < ActiveRecord::Migration

  def self.up
    add_column :projects, :quotes_count, :integer, :default => 0
  end

  def self.down
    remove_column :projects, :quotes_count
  end

end
