class AddRequireFileReferenceToExternalCompanies < ActiveRecord::Migration

  def up
    add_column :external_companies, :require_file_reference, :boolean, :default => false
  end

  def down
    remove_column :external_companies, :require_file_reference
  end

end
