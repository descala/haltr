class ExternalCompany < ActiveRecord::Base

  unloadable

  has_many :clients,
    :as        => :company,
    :dependent => :nullify

  validates_presence_of :name, :postalcode, :country
  validates_presence_of :taxcode, :unless => Proc.new {|ec|
    Company::COUNTRIES_WITHOUT_TAXCODE.include? ec.country
  }
  validates_length_of :taxcode, :maximum => 20
  validates_uniqueness_of :taxcode, :allow_blank => true
  validates_inclusion_of :currency, :in => Money::Currency.table.collect {|k,v| v[:iso_code] }
  validates_format_of :email,
    :with => /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+(,[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+)*\z/,
    :allow_nil => true,
    :allow_blank => true
  validates_format_of [:organs_gestors,:unitats_tramitadores,:oficines_comptables,:organs_proponents],
    :with => /^[0-9, ]$/,
    :allow_nil => true,
    :allow_blank => true
  after_save :update_linked_clients
  iso_country :country
  include CountryUtils

  attr_accessor :require_dir3, :require_organ_proponent, :require_ponumber, :require_despatch_advice

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
    Dir3Entity.where(:id => organs_gestors.to_s.split(/[,\n]/))
  end

  def dir3_unitats_tramitadores
    Dir3Entity.where(:id => unitats_tramitadores.to_s.split(/[,\n]/))
  end

  def dir3_oficines_comptables
    Dir3Entity.where(:id => oficines_comptables.to_s.split(/[,\n]/))
  end

  def dir3_organs_proponents
    Dir3Entity.where(:id => organs_proponents.to_s.split(/[,\n]/))
  end

end
