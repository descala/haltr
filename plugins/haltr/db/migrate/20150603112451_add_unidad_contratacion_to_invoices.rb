class AddUnidadContratacionToInvoices < ActiveRecord::Migration

  def up
    add_column :invoices, :unidad_contratacion, :string
  end

  def down
    remove_column :invoices, :unidad_contratacion
  end

end
