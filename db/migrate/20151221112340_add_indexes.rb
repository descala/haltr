class AddIndexes < ActiveRecord::Migration

  def up
    add_index :invoices, [:project_id, :created_at]  # Old Invoices alert
    add_index :events, [:project_id, :created_at]    # Last project events
    add_index :invoices, :quote_id
    add_index :clients, :name
    add_index :companies, :name
  end

  def down
    remove_index :invoices, [:project_id, :created_at]
    remove_index :events, [:project_id, :created_at]
    remove_index :invoices, :quote_id
    remove_index :clients, :name
    remove_index :companies, :name
  end

end
