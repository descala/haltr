class AddEvenMoreIndexes < ActiveRecord::Migration

  def change
    add_index :events, :client_id
    add_index :events, :created_at
    add_index :invoices, :created_at
    add_index :invoices, :state
    add_index :import_errors, :project_id
    add_index :mandates, :client_id
  end

end
