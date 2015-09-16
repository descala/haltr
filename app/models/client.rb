class Client < ActiveRecord::Base

  unloadable
  audited except: [:hashid, :project]
  # do not remove, with audit we need to make the other attributes accessible
  attr_protected :created_at, :updated_at

  include Haltr::BankInfoValidator
  has_many :invoices, :dependent => :destroy
  has_many :people,   :dependent => :destroy
  has_many :mandates, :dependent => :destroy
  has_many :events,   :order => :created_at
  has_many :client_offices, :dependent => :destroy

  belongs_to :project   # client of
  belongs_to :company,  # linked to
    :polymorphic => true
  belongs_to :bank_info # refers to company's bank_info
                        # default one when creating new invoices

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
  before_save :set_hashid_value
  before_save :copy_linked_profile
  after_create  :create_event
  iso_country :country
  include CountryUtils
  include Haltr::TaxcodeValidator

  after_initialize :set_default_values

  def set_default_values
    self.currency       ||= Setting.plugin_haltr['default_currency']
    self.country        ||= Setting.plugin_haltr['default_country']
    self.invoice_format ||= ExportChannels.default
    self.sepa_type      ||= "CORE"
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

  def bank_invoices(due_date,bank_info_id)
    IssuedInvoice.where(
      client_id:      self.id,
      state:          ['sent','registered'],
      payment_method: Invoice::PAYMENT_DEBIT,
      due_date:       due_date,
      bank_info_id:   bank_info_id
    )
  end

  def bank_invoices_total(due_date, bank_info_id)
    a = Money.new 0, Money::Currency.new(Setting.plugin_haltr['default_currency'])
    bank_invoices(due_date, bank_info_id).each { |i| a = i.total + a }
    a
  end

  def to_label
    name.nil? ? taxcode : name
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
    if self.linked? and company.project
      begin
        company.project.users.reject {|u| u.admin? }.first.language
      rescue
        company.project.users.first.language rescue User.current.language
      end
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

  def set_if_blank(atr,val)
    if send("read_attribute",atr).blank?
      send("#{atr}=",val)
    elsif send(atr) != val
      raise "client #{atr} does not match (#{send(atr)} != #{val})"
    end
  end

  def bank_account
    if read_attribute(:bank_account).blank? and !read_attribute(:iban).blank?
      BankInfo.iban2local(country,read_attribute(:iban))
    else
      read_attribute(:bank_account)
    end
  end

  def iban
    if read_attribute(:iban).blank? and !read_attribute(:bank_account).blank?
      BankInfo.local2iban(country,read_attribute(:bank_account))
    else
      read_attribute(:iban)
    end
  end

  def last_audits_without_event
    audts = (self.audits.where('event_id is NULL')).group_by(&:created_at)
    last = audts.keys.sort.last
    audts[last] || []
  end

  def recipient_people
    people.find(:all,:order=>'last_name ASC',:conditions=>['send_invoices_by_mail = true'])
  end

  def recipient_emails
    mails = recipient_people.collect do |person|
      person.email if person.email.present?
    end
    mails << email if email.present?
    mails.uniq.compact
  end

  protected

  # called after_create (only NEW clients)
  def create_event
    event = Event.new(:name=>'new',:client=>self,:user=>User.current)
    event.audits = self.last_audits_without_event
    event.save!
  end

  private

  def copy_linked_profile
    if self.company and self.allowed?
      %w(taxcode company_identifier name email currency postalcode country province city address website invoice_format language).each do |attr|
        self.send("#{attr}=",company.send(attr))
      end
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
