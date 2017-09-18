class AddPartyIdentificationToInvoices < ActiveRecord::Migration

  def up
    add_column :invoices, :party_identification, :string
  end

  def down
    remove_column :invoices, :party_identification
  end

end
