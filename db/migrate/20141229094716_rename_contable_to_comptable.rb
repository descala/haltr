class RenameContableToComptable < ActiveRecord::Migration

  def up
    rename_column :dir3s, :oficina_contable_id, :oficina_comptable_id
  end

  def down
    rename_column :dir3s, :oficina_comptable_id, :oficina_contable_id
  end

end
