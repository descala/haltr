class DelayedJobsBiggerHandler < ActiveRecord::Migration

  def self.up
    change_column :delayed_jobs, :handler, :text, :limit => 16777215
  end

  def self.down
    change_column :import_errors, :original, :text, :limit => 65535
  end

end
