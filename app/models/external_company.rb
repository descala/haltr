class ExternalCompany < ActiveRecord::Base

  unloadable

  has_many :clients,
    :as        => :company,
    :dependent => :nullify

  validates_presence_of :name, :postalcode, :country
  validates_length_of :taxcode, :maximum => 20
  validates_uniqueness_of :taxcode, :allow_blank => true
  validates_inclusion_of :currency, :in => Money::Currency.table.collect {|k,v| v[:iso_code] }
  validates_format_of :email,
    :with => /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+(,[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+)*\z/,
    :allow_nil => true,
    :allow_blank => true
  validates_format_of [:organs_gestors,:unitats_tramitadores,:oficines_comptables,:organs_proponents],
    :with => /^[A-Z0-9, ]*$/i,
    :allow_nil => true,
    :allow_blank => true

  after_save :update_linked_clients
  iso_country :country
  include CountryUtils
  include Haltr::TaxcodeValidator

  serialize :fields_config
  before_save {
    # make required fields always visible
    AVAILABLE_FIELDS.each do |field|
      if self.send("required_#{field}")
        self.send("visible_#{field}=","1")
      end
    end
  }
  AVAILABLE_FIELDS=%w(dir3 organ_proponent ponumber delivery_note_number file_reference payments_on_account receiver_contract_reference)
  AVAILABLE_FIELDS.each do |field|
    src = <<-END_SRC
      def visible_#{field}
        initalize_fields_config
        fields_config["visible"]["#{field}"] == "1" rescue false
      end

      def visible_#{field}=(v)
        initalize_fields_config
        fields_config["visible"] ||= {}
        v = '1' if v == true or v == 'true'
        fields_config["visible"]["#{field}"] = v
      end

      def required_#{field}
        initalize_fields_config
        fields_config["required"]["#{field}"] == "1" rescue false
      end

      def required_#{field}=(v)
        initalize_fields_config
        fields_config["required"] ||= {}
        v = '1' if v == true or v == 'true'
        fields_config["required"]["#{field}"] = v
      end
    END_SRC
    class_eval src, __FILE__, __LINE__
  end

  def initalize_fields_config
    self.fields_config ||= {"visible" => {}, "required" => {}}
  end

  def required_fields
    AVAILABLE_FIELDS.collect {|field|
      field if self.send("required_#{field}")
    }.compact
  end

  def visible_fields
    AVAILABLE_FIELDS.collect {|field|
      field if self.send("visible_#{field}")
    }.compact
  end

  def project
    nil
  end

  def public?
    true
  end

  def semipublic?
    false
  end

  def private?
    false
  end

  def update_linked_clients
    self.clients.each do |client|
      client.save
    end
  end

  def dir3_organs_gestors
    og = Dir3Entity.where(:code => organs_gestors.to_s.split(/[,\n]/))
    organs_gestors.to_s.split(/[,\n]/).uniq.collect {|code|
      og.find_by_code(code) || Dir3Entity.new(name: code, code: code)
    }
  end

  def dir3_unitats_tramitadores
    ut = Dir3Entity.where(:code => unitats_tramitadores.to_s.split(/[,\n]/))
    unitats_tramitadores.to_s.split(/[,\n]/).uniq.collect {|code|
      ut.find_by_code(code) || Dir3Entity.new(name: code, code: code)
    }
  end

  def dir3_oficines_comptables
    oc = Dir3Entity.where(:code => oficines_comptables.to_s.split(/[,\n]/))
    oficines_comptables.to_s.split(/[,\n]/).uniq.collect {|code|
      oc.find_by_code(code) || Dir3Entity.new(name: code, code: code)
    }
  end

  def dir3_organs_proponents
    op = Dir3Entity.where(:code => organs_proponents.to_s.split(/[,\n]/))
    organs_proponents.to_s.split(/[,\n]/).uniq.collect {|code|
      op.find_by_code(code) || Dir3Entity.new(name: code, code: code)
    }
  end

end
