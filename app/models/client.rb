class Client < ActiveRecord::Base

  unloadable

  has_many :invoices ##, :dependent => :nullify ## NO ESBORRAR CLIENTS
  has_many :people

  # TODO: only in Redmine
  belongs_to :project, :include => true
  belongs_to :company

  validates_presence_of   :taxcode, :hashid
  validates_length_of     :taxcode, :maximum => 20
  validates_uniqueness_of :taxcode, :scope => :project_id
  validates_uniqueness_of :hashid

  validates_presence_of     :project_id, :name, :currency, :language, :invoice_format, :if => Proc.new {|c| c.company_id.blank? }
  validates_inclusion_of    :currency, :in  => Money::Currency::TABLE.collect {|k,v| v[:iso_code] }, :if => Proc.new {|c| c.company_id.blank? }
  validates_numericality_of :bank_account, :unless => Proc.new { |c| c.bank_account.blank? }
  validates_length_of       :bank_account, :within => 16..40, :unless => Proc.new { |c| c.bank_account.blank? }
#  validates_uniqueness_of :name, :scope => :project_id
#  validates_length_of :name, :maximum => 30
#  validates_format_of :identifier, :with => /^[a-z0-9\-]*$/

  before_validation :set_hashid_value
  before_validation :copy_linked_profile
  iso_country :country
  include CountryUtils

  def initialize(attributes=nil)
    super
    self.currency ||= Money.default_currency.iso_code
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
    IssuedInvoice.find :all, :conditions => ["client_id = ? and state = 'sent' and draft = ? and payment_method=#{Invoice::PAYMENT_DEBIT} and due_date = ?", self, false, due_date ]
  end

  def bank_invoices_total(due_date)
    a = Money.new 0
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

  def before_destroy
    if self.invoices.any?
      #TODO: this error not shown
      errors.add_to_base("Client has #{invoices.size} invoices associated")
      false
    end
  end

  def allowed?
    self.company and ( self.company.public? || self.company.semipublic? and self.allowed )
  end

  def denied?
    self.company and ( self.company.private? || self.company.semipublic? and self.allowed == false )
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

  def full_address
    addr = address
    addr += "\n#{address2}" if address2
    addr
  end

  private

  def copy_linked_profile
    if self.company and self.allowed?
      %w(taxcode name email currency postalcode country province city address website invoice_format).each do |attr|
        self.send("#{attr}=",company.send(attr))
      end
      self.language = company.project.users.collect {|u| u unless u.admin?}.compact.first.language rescue I18n.default_locale
    elsif !self.company
      self.allowed = nil
    end
  end

  def set_hashid_value
    unless hashid
      require "md5"
      self.hashid=MD5.hexdigest(Time.now.to_f.to_s)[0...10]
    end
  end

end
