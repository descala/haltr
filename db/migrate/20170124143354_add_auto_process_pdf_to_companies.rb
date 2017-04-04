class AddAutoProcessPdfToCompanies < ActiveRecord::Migration

  def change
    add_column :companies, :auto_process_pdf, :boolean, default: false
  end

end
