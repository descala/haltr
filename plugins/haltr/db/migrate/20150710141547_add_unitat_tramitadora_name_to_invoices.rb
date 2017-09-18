class AddUnitatTramitadoraNameToInvoices < ActiveRecord::Migration

  def up
    add_column :invoices, :unitat_tramitadora_name, :string
  end

  def down
    remove_column :invoices, :unitat_tramitadora_name
  end

end
