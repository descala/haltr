class Dir3sToExternalCompanies < ActiveRecord::Migration

  def up
    add_column :external_companies, :organs_gestors,       :text
    add_column :external_companies, :unitats_tramitadores, :text
    add_column :external_companies, :oficines_comptables,  :text
    add_column :external_companies, :organs_proponents,    :text

    ExternalCompany.reset_column_information

    Dir3.all.group_by(&:taxcode).each do |taxcode,dir3s|
      extcomp = ExternalCompany.find_by_taxcode taxcode
      next unless extcomp

      organs_gestors=[]
      unitats_tramitadores=[]
      oficines_comptables=[]

      dir3s.each do |dir3|
        organs_gestors       << dir3.organ_gestor_id
        unitats_tramitadores << dir3.unitat_tramitadora_id
        oficines_comptables  << dir3.oficina_comptable_id
      end

      extcomp.organs_gestors       = organs_gestors.compact.join(',')
      extcomp.unitats_tramitadores = unitats_tramitadores.compact.join(',')
      extcomp.oficines_comptables  = oficines_comptables.compact.join(',')

      extcomp.save(:validate => false)
    end
  end

  def down
    remove_column :external_companies, :organs_gestors
    remove_column :external_companies, :unitats_tramitadores
    remove_column :external_companies, :oficines_comptables
    remove_column :external_companies, :organs_proponents
  end

end
