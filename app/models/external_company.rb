class ExternalCompany < ActiveRecord::Base

  unloadable

  has_many :clients,
    :as        => :company,
    :dependent => :nullify

  validates_presence_of :name, :email, :postalcode, :country
  validates_presence_of :taxcode, :unless => Proc.new {|ec|
    Company::COUNTRIES_WITHOUT_TAXCODE.include? ec.country
  }
  validates_length_of :taxcode, :maximum => 20
  validates_uniqueness_of :taxcode, :allow_blank => true
  validates_inclusion_of :currency, :in => Money::Currency.table.collect {|k,v| v[:iso_code] }
  validates_format_of :email,
    :with => /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+(,[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+)*\z/,
    :allow_nil => true
  after_save :update_linked_clients
  iso_country :country
  include CountryUtils

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

end
