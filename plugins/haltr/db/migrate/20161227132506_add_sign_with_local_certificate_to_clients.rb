class AddSignWithLocalCertificateToClients < ActiveRecord::Migration

  def change
    add_column :clients, :sign_with_local_certificate, :boolean, default: false
  end

end
