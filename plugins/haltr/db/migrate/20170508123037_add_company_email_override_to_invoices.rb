class AddCompanyEmailOverrideToInvoices < ActiveRecord::Migration

  def change
    add_column :invoices, :company_email_override, :string
  end

end
