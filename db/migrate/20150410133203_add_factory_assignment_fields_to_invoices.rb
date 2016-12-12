class AddFactoryAssignmentFieldsToInvoices < ActiveRecord::Migration

  def up
    add_column :invoices, :fa_person_type,    :string
    add_column :invoices, :fa_residence_type, :string
    add_column :invoices, :fa_taxcode,        :string
    add_column :invoices, :fa_name,           :string
    add_column :invoices, :fa_address,        :string
    add_column :invoices, :fa_postcode,       :string
    add_column :invoices, :fa_town,           :string
    add_column :invoices, :fa_province,       :string
    add_column :invoices, :fa_country,        :string
    add_column :invoices, :fa_info,           :string
    add_column :invoices, :fa_duedate,        :date
    add_column :invoices, :fa_import,         :decimal, precision: 18, scale: 9
    add_column :invoices, :fa_payment_method, :string
    add_column :invoices, :fa_iban,           :string
    add_column :invoices, :fa_bank_code,      :string
    add_column :invoices, :fa_clauses,        :text
  end

  def down
    remove_column :invoices, :fa_person_type
    remove_column :invoices, :fa_residence_type
    remove_column :invoices, :fa_taxcode
    remove_column :invoices, :fa_name
    remove_column :invoices, :fa_address
    remove_column :invoices, :fa_postcode
    remove_column :invoices, :fa_town
    remove_column :invoices, :fa_province
    remove_column :invoices, :fa_country
    remove_column :invoices, :fa_info
    remove_column :invoices, :fa_duedate
    remove_column :invoices, :fa_import
    remove_column :invoices, :fa_payment_method
    remove_column :invoices, :fa_iban
    remove_column :invoices, :fa_bank_code
    remove_column :invoices, :fa_clauses
  end

end
