class AddEventIdToAudits < ActiveRecord::Migration

  def up
    add_column :audits, :event_id, :integer
  end

  def down
    remove_column :audits, :event_id
  end

end
