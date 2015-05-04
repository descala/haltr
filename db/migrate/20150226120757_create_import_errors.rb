class CreateImportErrors < ActiveRecord::Migration

  def change
    create_table :import_errors do |t|
      t.string  :filename
      t.string  :import_errors
      t.text    :original
      t.integer :project_id

      t.timestamps null: false
    end
  end

end
