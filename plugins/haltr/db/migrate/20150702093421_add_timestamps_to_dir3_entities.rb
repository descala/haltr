class AddTimestampsToDir3Entities < ActiveRecord::Migration

  def change
    change_table(:dir3_entities) { |t| t.timestamps null: false }
  end

end
