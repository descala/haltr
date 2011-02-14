class ChangeCompaniesPublic < ActiveRecord::Migration
  def self.up
    # Company.all.collect {|c| c.public = c.public=="1" ? "public" : "private" ; c.save }
    change_column :companies, :public, :string, :default => 'private'
  end

  def self.down
    change_column :companies, :public, :boolean, :default => 'false'
  end
end
