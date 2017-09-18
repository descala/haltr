class ChangeImportErrorsImportErrorsColumnType < ActiveRecord::Migration
  def self.up
    change_column :import_errors, :import_errors, :text, :limit => 65535
  end
  def self.down
    change_column :import_errors, :import_errors, :string
  end
end
