class AddUnitatContractacioToInvoices < ActiveRecord::Migration

  def up
    add_column :invoices, :unitat_contractacio, :string
  end

  def down
    remove_column :invoices, :unitat_contractacio
  end

end
