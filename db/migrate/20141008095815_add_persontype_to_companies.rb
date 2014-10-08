class AddPersontypeToCompanies < ActiveRecord::Migration

  def up
    add_column :companies, :persontype, :string, :default => 'J'
  end

  def down
    remove_column :companies, :persontype
  end

end
