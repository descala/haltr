class Dir3 < ActiveRecord::Base
  unloadable
  # dir3.clients has no sense
  belongs_to :organ_gestor,
    :class_name  => 'Dir3Entity',
    :foreign_key => :organ_gestor_id,
    :primary_key => :code
  belongs_to :unitat_tramitadora,
    :class_name  => 'Dir3Entity',
    :foreign_key => :unitat_tramitadora_id,
    :primary_key => :code
  belongs_to :oficina_contable,
    :class_name  => 'Dir3Entity',
    :foreign_key => :oficina_contable_id,
    :primary_key => :code
end
