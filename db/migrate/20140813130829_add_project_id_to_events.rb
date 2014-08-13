class AddProjectIdToEvents < ActiveRecord::Migration

  def up
    add_column :events, :project_id, :integer
    execute "update events set project_id=(select project_id from invoices where invoices.id=events.invoice_id);"
  end

  def down
    remove_column :events, :project_id
  end

end
