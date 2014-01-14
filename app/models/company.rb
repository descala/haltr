class Company < ActiveRecord::Base

  unloadable

  belongs_to :project

  # these are the linked clients: where this company apears in other 
  # companies' client list
  has_many :clients, :dependent => :nullify
  has_many :taxes, :class_name => "Tax", :dependent => :destroy, :order => "name,percent DESC"
  has_many :bank_infos, :dependent => :destroy, :order => "name,bank_account,iban,bic DESC"
  COUNTRIES_WITHOUT_TAXCODE = ["is","no"]
  validates_presence_of :name, :project_id, :email, :postalcode, :country
  validates_presence_of :taxcode, :unless => Proc.new {|company|
    COUNTRIES_WITHOUT_TAXCODE.include? company.country
  }
  validates_length_of :taxcode, :maximum => 20
  validates_uniqueness_of :taxcode, :allow_blank => true
  validates_inclusion_of :currency, :in  => Money::Currency.table.collect {|k,v| v[:iso_code] }
  validates_format_of :email,
    :with => /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+(,[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+)*\z/,
    :allow_nil => true
  validate :only_one_default_tax_per_name
  acts_as_attachable :view_permission => :general_use,
                     :delete_permission => :general_use
  after_save :update_linked_clients
  iso_country :country
  include CountryUtils

  accepts_nested_attributes_for :taxes,
    :allow_destroy => true,
    :reject_if => proc { |attributes| attributes.all? { |_, value| value.blank? } }
  validates_associated :taxes

  accepts_nested_attributes_for :bank_infos,
    :allow_destroy => true,
    :reject_if => proc { |attributes| attributes.all? { |_, value| value.blank? } }
  validates_associated :bank_infos

  validate :uniqueness_of_taxes

  def initialize(attributes=nil)
    super
    #TODO: Add default country taxes
    self.currency ||= Setting.plugin_haltr['default_currency']
    self.country  ||= Setting.plugin_haltr['default_country']
    self.attachments ||= []
  end

  def <=>(oth)
    self.name <=> oth.name
  end

  def first_name
    name.split(" ").first
  end

  def last_name
    ln = name.split(" ")
    ln.shift
    ln.join(" ")
  end

  def currency=(v)
    return unless v
    write_attribute(:currency,v.upcase)
  end

  def public?
    self.public == "public"
  end

  def semipublic?
    self.public == "semipublic"
  end

  def private?
    self.public == "private"
  end

  def companies_with_link_requests
    self.clients.collect do |client|
      next unless client.project and client.project.company
      client.project.company if client.allowed?.nil?
    end.compact
  end

  def taxcode=(tc)
    # taxcode is used to retrieve logo on xhtml when transforming to PDF,
    # some chars will make logo retrieval fail (i.e. spaces)
    write_attribute(:taxcode,tc.to_s.gsub(/\W/,''))
  end

  def only_one_default_tax_per_name
    deftaxes = {}
    taxes.each do |tax|
      errors.add(:base, l(:only_one_default_allowed_for, :tax_name=>tax.name)) if deftaxes[tax.name] and tax.default
      deftaxes[tax.name] = tax.default
    end
  end

  def tax_names
    taxes.collect {|tax| tax.name }.uniq
  end

  def bank_accounts
    self.bank_infos.collect {|bi|
      bi.bank_account
    }.compact.uniq
  end

  # workaround rails bug that allows to save invalid taxes on company
  # see https://github.com/rails/rails/issues/4568
  def uniqueness_of_taxes
    my_taxes = {}
    taxes.each do |tax|
      next if tax.marked_for_destruction?
      nc = "#{tax[:name]}#{tax[:category]}"
      my_taxes[tax.percent] = [] unless my_taxes.has_key?(tax.percent)
      errors.add(:taxes, :invalid) if my_taxes[tax.percent].include?(nc)
      my_taxes[tax.percent] << nc
    end
  end

  # http://inza.wordpress.com/2013/10/25/como-preparar-los-mandatos-sepa-identificador-del-acreedor/
  def sepa_creditor_identifier
    num = "#{taxcode}#{country_alpha2}00".downcase.each_byte.collect do |c|
      if c <= 57
        c.chr
      else
        c - 87
      end
    end.join.to_i
    # MOD97-10 from ISO 7064
    control = 98 - ( num % 97 )
    "#{country_alpha2}#{control}000#{taxcode}"
  end

  private

  def update_linked_clients
    self.clients.each do |client|
      if self.private?
        client.company=nil
        client.allowed=nil
      end
      client.save
    end
  end

end
