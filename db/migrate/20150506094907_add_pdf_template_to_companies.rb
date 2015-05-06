class AddPdfTemplateToCompanies < ActiveRecord::Migration

  def up
    add_column :companies, :pdf_template, :string
  end

  def down
    remove_column :companies, :pdf_template
  end

end
