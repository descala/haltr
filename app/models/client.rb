class Client < ActiveRecord::Base

  unloadable

  include Haltr::BankInfoValidator
  has_many :invoices, :dependent => :destroy
  has_many :people, :dependent => :destroy

  belongs_to :project # client of
  belongs_to :company # linked to
  belongs_to :bank_info # refers to company's bank_info
                        # default one when creating new invoices

  validates_presence_of :taxcode, :unless => Proc.new { |client|
    Company::COUNTRIES_WITHOUT_TAXCODE.include? client.country
  }
  validates_presence_of :hashid
  validates_uniqueness_of :taxcode, :scope => :project_id, :allow_blank => true
  validates_uniqueness_of :hashid

  validates_presence_of     :project_id, :name, :currency, :language, :invoice_format, :if => Proc.new {|c| c.company_id.blank? }
  validates_inclusion_of    :currency, :in  => Money::Currency.table.collect {|k,v| v[:iso_code] }, :if => Proc.new {|c| c.company_id.blank? }
  validates_format_of       :email, :with => /\A([\w\.\-\+]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, :allow_nil => true, :allow_blank => true
  validate :bank_info_belongs_to_self
#  validates_uniqueness_of :name, :scope => :project_id
#  validates_length_of :name, :maximum => 30
#  validates_format_of :identifier, :with => /^[a-z0-9\-]*$/

  before_validation :set_hashid_value
  before_validation :copy_linked_profile
  iso_country :country
  include CountryUtils

  def initialize(attributes=nil)
    super
    self.currency ||= Setting.plugin_haltr['default_currency']
    self.country  ||= Setting.plugin_haltr['default_country']
    self.invoice_format ||= ExportChannels.default
    self.language ||= User.current.language
    self.language = "es" if self.language.blank?
  end

  # Masks db value with default if db value is deprecated
  def invoice_format
    format = read_attribute(:invoice_format)
    format = ExportChannels.default unless ExportChannels.available? format
    return format
  end

  def currency=(v)
    write_attribute(:currency,v.upcase)
  end

  def bank_invoices(due_date)
    IssuedInvoice.find :all, :conditions => ["client_id = ? and state = 'sent' and payment_method=#{Invoice::PAYMENT_DEBIT} and due_date = ?", self, due_date ]
  end

  def bank_invoices_total(due_date)
    a = Money.new 0, Money::Currency.new(Setting.plugin_haltr['default_currency'])
    bank_invoices(due_date).each { |i| a = i.total + a }
    a
  end

  def to_label
    name
  end

  alias :to_s :to_label

  def invoice_templates
    self.invoices.find(:all,:conditions=>["type=?","InvoiceTemplate"])
  end

  def invoice_documents
    self.invoices.find(:all,:conditions=>["type=?","IssuedInvoice"])
  end

  def issued_invoices
    self.invoices.find(:all,:conditions=>["type=?","IssuedInvoice"])
  end

  def received_invoices
    self.invoices.find(:all,:conditions=>["type=?","ReceivedInvoice"])
  end

  def allowed?
    self.company and ( self.company.public? || ( self.company.semipublic? and self.allowed ) )
  end

  def denied?
    self.company and ( self.company.private? || ( self.company.semipublic? and self.allowed == false ) )
  end

  def linked?
    self.company and !self.denied?
  end

  def language
    if self.linked?
      company.project.users.collect {|u| u unless u.admin?}.compact.first.language rescue read_attribute(:language)
    else
      read_attribute(:language)
    end
  end

  # removes non ascii characters from language code
  # for safe xml generation
  def language_string
    self.language.scan(/[a-z]+/i).first
  end

  def full_address
    addr = address
    addr += "\n#{address2}" if address2
    addr
  end

  def payment_method=(v)
    if v =~ /_/
      write_attribute(:payment_method,v.split("_")[0])
      self.bank_info_id=v.split("_")[1]
    else
      write_attribute(:payment_method,v)
      self.bank_info=nil
    end
  end

  def payment_method
    if [Invoice::PAYMENT_TRANSFER, Invoice::PAYMENT_DEBIT].include?(read_attribute(:payment_method)) and bank_info
      "#{read_attribute(:payment_method)}_#{bank_info.id}"
    else
      read_attribute(:payment_method)
    end
  end

  private

  def copy_linked_profile
    if self.company and self.allowed?
      %w(taxcode company_identifier name email currency postalcode country province city address website invoice_format).each do |attr|
        self.send("#{attr}=",company.send(attr))
      end
      self.language = company.project.users.collect {|u| u unless u.admin?}.compact.first.language rescue I18n.default_locale.to_s
    elsif !self.company
      self.allowed = nil
    end
  end

  def set_hashid_value
    unless hashid
      require "digest/md5"
      self.hashid=Digest::MD5.hexdigest(Time.now.to_f.to_s)[0...10]
    end
  end

  def bank_info_belongs_to_self
    if bank_info and bank_info.company != project.company
      errors.add(:base, "Bank info is from other company!")
    end
  end

end
