class AddMoreIndexes < ActiveRecord::Migration

  def up
    add_index :external_companies, :taxcode
    add_index :dir3_entities, :code
    add_index :events, :project_id
    add_index :events, :type
    add_index :audits, :event_id
  end

  def down
    remove_index :external_companies, :taxcode
    remove_index :dir3_entities, :code
    remove_index :events, :project_id
    remove_index :events, :type
    remove_index :audits, :event_id
  end

end
