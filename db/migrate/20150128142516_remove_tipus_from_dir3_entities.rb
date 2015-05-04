class RemoveTipusFromDir3Entities < ActiveRecord::Migration

  def up
    remove_column :dir3_entities, :tipus
  end

  def down
    add_column :dir3_entities, :tipus, :string
  end

end
