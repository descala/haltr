class AddOficinaComptableNameToInvoices < ActiveRecord::Migration

  def up
    add_column :invoices, :oficina_comptable_name, :string
  end

  def down
    remove_column :invoices, :oficina_comptable_name
  end

end
