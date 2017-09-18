class AddClientIdToEvents < ActiveRecord::Migration

  def up
    add_column :events, :client_id, :integer
  end

  def down
    remove_column :events, :client_id
  end

end
