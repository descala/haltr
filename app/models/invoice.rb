class Invoice < ActiveRecord::Base

  unloadable

  # Invoice statuses
  STATUS_NOT_SENT = 1
  STATUS_SENT     = 5
  STATUS_CLOSED   = 9

  # Default tax %
  TAX = 18

  STATUS_LIST = { STATUS_NOT_SENT=>'Not sent', STATUS_SENT=>'Sent', STATUS_CLOSED=>'Closed' }


  has_many :invoice_lines, :dependent => :destroy
  belongs_to :client
  validates_presence_of :client, :date, :currency
  validates_inclusion_of :currency, :in  => Money::Currency::TABLE.collect {|k,v| v[:iso_code] }

  accepts_nested_attributes_for :invoice_lines,
    :allow_destroy => true,
    :reject_if => proc { |attributes| attributes.all? { |_, value| value.blank? } }
  validates_associated :invoice_lines

  before_validation :set_due_date
  before_save :update_import

  composed_of :import,
    :class_name => "Money",
    :mapping => [%w(import_in_cents cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) }

  def initialize(attributes=nil)
    super
    self.discount_percent ||= 0
    self.currency ||= self.client.currency rescue nil
    self.currency ||= self.client.company.currency rescue nil
    self.currency ||= Money.default_currency.iso_code
  end

  def currency=(v)
    write_attribute(:currency,v.upcase)
    invoice_lines.each do |il|
      # replace price since it's frozen.
      # il.currency='xxx' does not update its money currency (!)
      il.price=Money.new(il.price_in_cents,v.upcase)
    end
  end

  def subtotal_without_discount
    total = Money.new(0,currency)
    invoice_lines.each do |line|
      next if line.destroyed?
      total += line.total
    end
    total
  end

  def subtotal
    subtotal_without_discount - discount
  end

  def tax
    subtotal * (tax_percent / 100.0)
  end

  def persontypecode
    if withholding_tax_percent > 0
      "F" # Fisica
    else
      "J" # Juridica
    end
  end

  def withholding_tax
    subtotal * (withholding_tax_percent / 100.0)
  end

  def withholding_tax_percent
    company.withholding_tax_percent.nil? ? 0 : company.withholding_tax_percent
  end

  def withholding_tax_name
    company.withholding_tax_name
  end

  def discount
    if discount_percent
      subtotal_without_discount * (discount_percent / 100.0)
    else
      Money.new(0,currency)
    end
  end

  def total
    subtotal + tax - withholding_tax
  end

  def subtotal_eur
    "#{subtotal} €"
  end

  def due
    "#{due_date}#{terms == "custom" ? "" : " (#{terms_description})"}"
  end

  def pdf_name
    "factura-#{number.gsub('/','')}.pdf"
  end

  def recipients
    Person.find(:all,:order=>'last_name ASC',:conditions => ["client_id = ? AND invoice_recipient = ?", client, true])
  end

  def self.last_number(project)
    i = InvoiceDocument.last(:order => "number", :include => [:client], :conditions => ["clients.project_id=? AND draft=?",project.id,false])
    i.number if i
  end

  def self.next_number(project)
    number = self.last_number(project)
    if number.nil?
      a = []
      num = 0
    else
      a = number.split('/')
      num = number.to_i
    end
    if a.size > 1
      a[1] =  sprintf('%03d', a[1].to_i + 1)
      return a.join("/")
    else
      return num + 1
    end
  end

  def sent?
    self.status > STATUS_NOT_SENT
  end

  def mark_closed
    update_attribute :status, STATUS_CLOSED
  end

  def mark_sent
    update_attribute :status, STATUS_SENT
  end

  def mark_not_sent
    update_attribute :status, STATUS_NOT_SENT
  end

  def closed?
    self.status == STATUS_CLOSED
  end


  def status_txt
    STATUS_LIST[self.status]
  end

  def terms_description
    terms_object.description
  end

  def payment_method
    if use_bank_account and client.bank_account and !client.bank_account.blank?
      ba = client.bank_account
      "Rebut domiciliat a #{ba[0..3]} #{ba[4..7]} ** ******#{ba[16..19]}"
    else
      ba = company.bank_account rescue ""
      "Pagament per transferència al compte #{ba[0..3]} #{ba[4..7]} #{ba[8..9]} #{ba[10..19]}"
    end
  end

  def <=>(oth)
    self.number <=> oth.number
  end

  def project
    self.client.project
  end

  def past_due?
    self.status < STATUS_CLOSED && due_date && due_date < Date.today
  end

  def company
    self.client.project.company
  end

  def custom_due?
    terms == "custom"
  end

  private

  def set_due_date
    self.due_date = terms_object.due_date unless terms == "custom"
  end

  def terms_object
    Terms.new(self.terms, self.date)
  end

  def update_import
    self.import_in_cents = subtotal.cents
  end

end
