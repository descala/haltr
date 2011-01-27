class AddFinalMd5ToEvents < ActiveRecord::Migration
  def self.up
    add_column :events, :final_md5, :string
  end

  def self.down
    remove_column :events, :final_md5
  end
end
