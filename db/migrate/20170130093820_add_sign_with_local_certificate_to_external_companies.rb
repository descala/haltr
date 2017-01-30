class AddSignWithLocalCertificateToExternalCompanies < ActiveRecord::Migration

  def change
    add_column :external_companies, :sign_with_local_certificate, :boolean, default: false
  end

end
