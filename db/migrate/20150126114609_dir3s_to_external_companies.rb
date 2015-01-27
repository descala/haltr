class Dir3sToExternalCompanies < ActiveRecord::Migration

  class Dir3 < ActiveRecord::Base
    belongs_to :organ_gestor,
      :class_name  => 'Dir3Entity',
      :foreign_key => :organ_gestor_id,
      :primary_key => :code
    belongs_to :unitat_tramitadora,
      :class_name  => 'Dir3Entity',
      :foreign_key => :unitat_tramitadora_id,
      :primary_key => :code
    belongs_to :oficina_comptable,
      :class_name  => 'Dir3Entity',
      :foreign_key => :oficina_comptable_id,
      :primary_key => :code
    has_many :invoices
  end

  def up
    add_column :external_companies, :organs_gestors,       :text
    add_column :external_companies, :unitats_tramitadores, :text
    add_column :external_companies, :oficines_comptables,  :text
    add_column :external_companies, :organs_proponents,    :text
    add_column :external_companies, :fields_config,        :text

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
    drop_table :dir3s

    if column_exists? :invoices, :num_albara
      rename_column :invoices, :num_albara, :delivery_note_number
    else
      add_column :invoices, :delivery_note_number, :string
    end
  end

  def down
    remove_column :external_companies, :organs_gestors
    remove_column :external_companies, :unitats_tramitadores
    remove_column :external_companies, :oficines_comptables
    remove_column :external_companies, :organs_proponents
    remove_column :external_companies, :fields_config
    create_table :dir3s do |t|
      t.string :taxcode
      t.string :organ_gestor_id
      t.string :unitat_tramitadora_id
      t.string :oficina_comptable_id
    end
    rename_column :invoices, :delivery_note_number, :num_albara
  end

end
