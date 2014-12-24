class RefactorDir3s < ActiveRecord::Migration

  def up
    add_column :invoices, :oficina_comptable, :string
    add_column :invoices, :organ_gestor, :string
    add_column :invoices, :unitat_tramitadora, :string
    add_column :invoices, :organ_proponent, :string

    Invoice.reset_column_information
    Invoice.where('dir3_id is not null').each do |invoice|
      invoice.update_attribute(:oficina_comptable,  invoice.dir3.oficina_contable.code)
      invoice.update_attribute(:organ_gestor,       invoice.dir3.organ_gestor.code)
      invoice.update_attribute(:unitat_tramitadora, invoice.dir3.unitat_tramitadora.code)
    end

    #TODO: remove_column :invoices, :dir3_id
  end

  def down
    remove_column :invoices, :oficina_comptable_code
    remove_column :invoices, :organ_gestor
    remove_column :invoices, :unitat_tramitadora
    remove_column :invoices, :organ_proponent
  end

end
