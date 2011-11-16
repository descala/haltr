class AddDibaFieldsToInvoices < ActiveRecord::Migration

  def self.up
    add_column :invoices, :num_contracte,      :string
    add_column :invoices, :num_expedient,      :string
    add_column :invoices, :codi_centre_gestor, :string
  end

  def self.down
    remove_column :invoices, :num_contracte
    remove_column :invoices, :num_expedient
    remove_column :invoices, :codi_centre_gestor
  end

end
