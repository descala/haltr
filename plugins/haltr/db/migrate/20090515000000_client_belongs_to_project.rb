class ClientBelongsToProject < ActiveRecord::Migration

  def self.up
    add_column :clients, :project_id,  :integer
  end

  def self.down
    remove_column :clients, :project_id
  end

end
