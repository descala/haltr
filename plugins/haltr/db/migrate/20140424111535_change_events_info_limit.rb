class ChangeEventsInfoLimit < ActiveRecord::Migration
  def self.up
    if ActiveRecord::Base.connection.adapter_name.downcase.starts_with? 'mysql'
      execute 'ALTER TABLE events MODIFY info MEDIUMTEXT;'
    end
  end
  def self.down
    if ActiveRecord::Base.connection.adapter_name.downcase.starts_with? 'mysql'
      execute 'ALTER TABLE events MODIFY info TEXT;'
    end
  end
end
