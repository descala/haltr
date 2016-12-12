class RemoveRequireFileReferenceFromExternalCompanies < ActiveRecord::Migration

  def up
    ExternalCompany.where('require_file_reference').each do |ec|
      ec.visible_file_reference = "1"
      ec.required_file_reference = "1"
      ec.save
    end
    remove_column :external_companies, :require_file_reference
  end

  def down
    add_column :external_companies, :require_file_reference, :boolean
  end

end
