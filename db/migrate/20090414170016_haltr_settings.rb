class HaltrSettings < ActiveRecord::Migration
  def self.up
    create_table :haltr_settings, :force => true do |t|
      t.column "name", :string, :limit => 50, :default => "", :null => false
      t.column "value", :text
      t.timestamps
    end
  end

  def self.down
    drop_table :haltr_settings
  end
end
