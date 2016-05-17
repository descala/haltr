class AddXpathsFromOriginalToClients < ActiveRecord::Migration

  def up
    add_column :clients, :xpaths_from_original, :text
  end

  def down
    remove_column :clients, :xpaths_from_original
  end

end
