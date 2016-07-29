class AddBccMeToCompanies < ActiveRecord::Migration

  def up
    add_column :companies, :bcc_me, :boolean, :default => true
  end

  def down
    remove_column :companies, :bcc_me
  end

end
