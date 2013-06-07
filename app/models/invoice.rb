class Invoice < ActiveRecord::Base

  include HaltrHelper

  unloadable

  # 1 - cash (al comptat)
  # 2 - debit (rebut domiciliat)
  # 4 - transfer (transferència)
  PAYMENT_CASH = 1
  PAYMENT_DEBIT = 2
  PAYMENT_TRANSFER = 4
  PAYMENT_SPECIAL = 13

  PAYMENT_CODES = {
    PAYMENT_CASH     => {:facturae => '01', :ubl => '10'},
    PAYMENT_DEBIT    => {:facturae => '02', :ubl => '49'},
    PAYMENT_TRANSFER => {:facturae => '04', :ubl => '31'},
    PAYMENT_SPECIAL  => {:facturae => '13', :ubl => '??'},
  }

  # remove non-utf8 characters from those fields:
  TO_UTF_FIELDS = %w(extra_info)

  attr_protected :created_at, :updated_at

  has_many :invoice_lines, :dependent => :destroy
  has_many :events, :dependent => :destroy
  #has_many :taxes, :through => :invoice_lines
  belongs_to :project, :counter_cache => true
  belongs_to :client
  belongs_to :amend, :class_name => "Invoice", :foreign_key => 'amend_id'
  has_one :amend_of, :class_name => "Invoice", :foreign_key => 'amend_id'
  validates_presence_of :client, :date, :currency, :project_id, :unless => Proc.new {|i| i.type == "ReceivedInvoice" }
  validates_inclusion_of :currency, :in  => Money::Currency.table.collect {|k,v| v[:iso_code] }, :unless => Proc.new {|i| i.type == "ReceivedInvoice" }

  # TODO warn the user it may not have the company or client bank account
  #      but does not force to have one (may be handled by an external system)
  # validate :payment_method_requirements, :unless => Proc.new {|i| i.type == "ReceivedInvoice" }

  before_save :fields_to_utf8
  after_create :increment_counter
  before_destroy :decrement_counter

  accepts_nested_attributes_for :invoice_lines,
    :allow_destroy => true,
    :reject_if => proc { |attributes| attributes.all? { |_, value| value.blank? } }
  validates_associated :invoice_lines

  composed_of :import,
    :class_name => "Money",
    :mapping => [%w(import_in_cents cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money::Currency.new(Setting.plugin_haltr['default_currency'])) }

  composed_of :total,
    :class_name => "Money",
    :mapping => [%w(total_in_cents cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money::Currency.new(Setting.plugin_haltr['default_currency'])) }

  composed_of :charge_amount,
    :class_name => "Money",
    :mapping => [%w(charge_amount_in_cents cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money::Currency.new(Setting.plugin_haltr['default_currency'])) }

  def initialize(attributes=nil)
    super
    self.discount_percent ||= 0
    self.currency ||= self.client.currency rescue nil
    self.currency ||= self.company.currency rescue nil
    self.currency ||= Setting.plugin_haltr['default_currency']
    self.payment_method ||= 1
  end

  def currency=(v)
    return unless v
    write_attribute(:currency,v.upcase)
    invoice_lines.each do |il|
      il.currency=v.upcase
    end
  end

  def gross_subtotal(tax_type=nil)
    amount = Money.new(0,currency)
    invoice_lines.each do |line|
      next if line.destroyed? or line.marked_for_destruction?
      amount += line.total if tax_type.nil? or line.has_tax?(tax_type)
    end
    amount
  end

  def subtotal_without_discount(tax_type=nil)
    gross_subtotal(tax_type) + charge_amount
  end

  def subtotal(tax_type=nil)
    subtotal_without_discount(tax_type) - discount(tax_type)
  end

  def persontypecode
    if taxes_withheld.any?
      "F" # Fisica
    else
      "J" # Juridica
    end
  end

  def discount(tax_type=nil)
    if discount_percent
      (subtotal_without_discount(tax_type) - charge_amount) * (discount_percent / 100.0)
    else
      Money.new(0,currency)
    end
  end

  def pdf_name
    "#{self.pdf_name_without_extension}.pdf" rescue "factura-___.pdf"
  end

  def pdf_name_without_extension
    "factura-#{number.gsub('/','')}" rescue "factura-___"
  end

  def recipient_people
    self.client.people.find(:all,:order=>'last_name ASC',:conditions=>['send_invoices_by_mail = true'])
  end

  def recipient_emails
    mails = self.recipient_people.collect do |person|
      person.email if person.email and !person.email.blank?
    end
    mails << self.client.email if self.client and self.client.email and !self.client.email.blank?
    # additional mails hook. it returns an array
    mails = mails + Redmine::Hook.call_hook(:model_invoice_additional_recipient_emails, :invoice=>self)
    mails.uniq.compact
  end

  def terms_description
    terms_object.description
  end

  def payment_method_string
    if debit? and client.use_iban?
      iban = client.iban || ""
      bic  = client.bic || ""
      "#{l(:debit_str)} BIC #{bic} IBAN #{iban[0..3]} #{iban[4..7]} #{iban[8..11]} **** **** #{iban[20..23]}"
    elsif transfer? and company.use_iban?
      iban = company.iban || ""
      bic  = company.bic || ""
      "#{l(:transfer_str)} BIC #{bic} IBAN #{iban[0..3]} #{iban[4..7]} #{iban[8..11]} #{iban[12..15]} #{iban[16..19]} #{iban[20..23]}"
    elsif debit?
      ba = client.bank_account || ""
      "#{l(:debit_str)} #{ba[0..3]} #{ba[4..7]} ** ******#{ba[16..19]}"
    elsif transfer?
      ba = company.bank_account ||= ""
      "#{l(:transfer_str)} #{ba[0..3]} #{ba[4..7]} #{ba[8..9]} #{ba[10..19]}"
    elsif special?
      payment_method_text
    else
      l(:cash_str)
    end
  end

  def self.payment_methods
    [[l("cash"), 1],[l("debit"), 2],[l("transfer"), 4],[l("other"),13]]
  end

  def debit?
    payment_method == PAYMENT_DEBIT
  end

  def transfer?
    payment_method == PAYMENT_TRANSFER
  end

  def special?
    payment_method == PAYMENT_SPECIAL
  end

  def payment_method_code(format)
    PAYMENT_CODES[payment_method][format]
  end

  def <=>(oth)
    if self.number.nil? and oth.number.nil?
      0
    elsif self.number.nil?
      -1
    elsif oth.number.nil?
      1
    else
      self.number <=> oth.number
    end
  end

  def company
    self.project.company
  end

  def custom_due?
    terms == "custom"
  end

  def locale
    begin
      client.language
    rescue
      I18n.default_locale
    end
  end 

  def amended?
    false # Only IssuedInvoices can be an amend
  end

  # cost de les taxes (Money)
  def tax_amount(tax_type=nil)
    t = Money.new(0,currency)
    if tax_type.nil?
      taxes_uniq.each do |tax|
        t += taxable_base(tax) * (tax.percent / 100.0)
      end
    else
      t += taxable_base(tax_type) * (tax_type.percent / 100.0)
    end
    t
  end

  def taxable_base(tax_type=nil)
    t = Money.new(0,currency)
    invoice_lines.each do |il|
      t += il.taxable_base if tax_type.nil? or il.has_tax?(tax_type)
    end
    t
  end

  def tax_applies_to_all_lines?(tax)
    taxable_base(tax) == subtotal
  end

  def taxes
    invoice_lines.collect {|l| l.taxes }.flatten.compact
  end

  def taxes_uniq
    #taxes.find :all, :group=> 'name,percent'
    tt=[]
    taxes.each {|tax|
      tt << tax unless tt.include? tax
    }
    tt
  end

  def tax_names
    taxes.collect {|tax| tax.name }.uniq
  end

  def taxes_hash
    th = {}
    # taxes defined in company
    company.taxes.each do |t|
      th[t.name] = [] unless th[t.name]
      th[t.name] << t
    end
    # add taxes from invoice, since we can have a tax
    # on invoice that is no longer defined in company
    taxes_uniq.each do |t|
      th[t.name] = [] unless th[t.name]
      th[t.name] << t unless th[t.name].include? t
    end
    th
  end

  # merge company and invoice taxes
  # to use in views
  def available_taxes
    available_taxes = company.taxes
    taxes_uniq.each do |tax|
      available_taxes << tax unless available_taxes.include? tax
    end
    available_taxes
  end

  def taxes_outputs
    #taxes.find(:all, :group => 'name,percent', :conditions => "percent >= 0")
    taxes_uniq.collect { |tax|
      tax if tax.percent >= 0
    }.compact
  end

  def total_tax_outputs
    t = Money.new(0,currency)
    taxes_outputs.each do |tax|
      t += tax_amount(tax)
    end
    t
  end

  def taxes_withheld
    #taxes.find(:all, :group => 'name,percent', :conditions => "percent < 0")
    taxes_uniq.collect {|tax|
      tax if tax.percent < 0
    }.compact
  end

  def total_taxes_withheld
    t = Money.new(0,currency)
    taxes_withheld.each do |tax|
      t += tax_amount(tax)
    end
    # here we have negative amount, pass it to positive (what facturae template expects)
    t * -1
  end

  def charge_amount=(value)
    value = Money.parse(value)
    write_attribute :charge_amount_in_cents, value.cents
  end

  def tax_per_line?(tax_name)
    return false if invoice_lines.first.nil?
    first_tax = invoice_lines.first.taxes.collect {|t| t if t.name == tax_name}.compact.first
    invoice_lines.each do |line|
      return true if line.taxes.collect {|t| t if t.name == tax_name}.compact.first != first_tax
    end
    false
  end

  def global_code_for(tax_name)
    return "" if tax_per_line? tax_name
    return "" if invoice_lines.first.nil?
    first_tax = invoice_lines.first.taxes.collect {|t| t if t.name == tax_name}.compact.first
    return "" if first_tax.nil?
    return first_tax.code
  end

  # Comments are stored on taxes but belong to invoices:
  # given a tax_name invoice can have a comment if there's one
  # line exempt from this tax.
  def global_comment_for(tax_name)
    (taxes + company.taxes).each do |tax|
      if tax.name == tax_name and tax.exempt?
        return tax.comment
      end
    end
    return ""
  end

  # Returns a hash with an example of all taxes that invoice uses.
  # Format of resulting hash:
  # { "VAT" => { "S" => [ tax_example, tax_example2 ], "E" => [ tax_example ] } }
  # tax_example should be passed tax_amount
  def taxes_by_category
    cts = {}
    taxes_outputs.each do |tax|
      cts[tax.name] = {}
    end
    taxes_outputs.each do |tax|
      unless cts[tax.name].values.flatten.include?(tax)
        cts[tax.name][tax.category] ||= []
        cts[tax.name][tax.category] << tax
      end
    end
    cts
  end

  def tax_amount_for(tax_name)
    t = Money.new(0,currency)
    taxes_uniq.each do |tax|
      next unless tax.name == tax_name
      t += tax_amount(tax)
    end
    t
  end

  def extra_info_plus_tax_comments
    tax_comments = self.taxes.collect do |tax|
      tax.comment
    end.compact.join(". ")
    if tax_comments and tax_comments.size > 0
      "#{extra_info}. #{tax_comments}".strip
    else
      extra_info
    end
  end

  def to_s
    lines_string = invoice_lines.collect do |line|
      line.to_s
    end.join("\n").gsub(/\n$/,'')
    <<_INV
#{self.class}
--
id = #{id}
number = #{number}
total = #{total}
--
#{lines_string}
_INV
  end

  protected

  def increment_counter
    Project.increment_counter "#{type.to_s.pluralize.underscore}_count", project_id
  end

  def decrement_counter
    Project.decrement_counter "#{type.to_s.pluralize.underscore}_count", project_id
  end

  # non-utf characters can break conversion to PDF and signature
  # done with external java software
  def fields_to_utf8
    TO_UTF_FIELDS.each do |f|
      self.send("#{f}=",Redmine::CodesetUtil.replace_invalid_utf8(self.send(f)))
    end
  end

  private

  def set_due_date
    self.due_date = terms_object.due_date unless terms == "custom"
  end

  def terms_object
    Terms.new(self.terms, self.date)
  end

  def update_imports
    #TODO: new invoice_line can't use invoice.discount without this
    # and while updating, lines have old invoice instance
    self.invoice_lines.each do |il|
      il.invoice = self
    end
    self.import_in_cents = subtotal.cents
    self.total_in_cents = subtotal.cents + tax_amount.cents
  end

  def payment_method_requirements
    if debit?
      c = Client.find client_id
      errors.add(:base, ("#{l(:field_payment_method)} (#{l(:debit)}) #{l(:requires_client_bank_account)}")) if c.bank_account.blank? and !c.use_iban?
    elsif transfer?
      errors.add(:base, ("#{l(:field_payment_method)} (#{l(:transfer)}) #{l(:requires_company_bank_account)}")) if company.bank_account.blank? and !company.use_iban?
    end
  end

  def invoice_must_have_lines
    if invoice_lines.empty? or invoice_lines.all? {|i| i.marked_for_destruction?}
      errors.add(:base, "#{l(:label_invoice)} #{l(:must_have_lines)}")
    end
  end

end
