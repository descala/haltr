class Invoice < ActiveRecord::Base

  unloadable

  # 1 - cash (al comptat)
  # 2 - debit (rebut domiciliat)
  # 4 - transfer (transferència)
  PAYMENT_CASH = 1
  PAYMENT_DEBIT = 2
  PAYMENT_TRANSFER = 4

  PAYMENT_CODES = {
    PAYMENT_CASH     => {:facturae => '01', :ubl => '10'},
    PAYMENT_DEBIT    => {:facturae => '02', :ubl => '49'},
    PAYMENT_TRANSFER => {:facturae => '04', :ubl => '31'},
  }

  # Default tax %
  TAX = 18

  has_many :invoice_lines, :dependent => :destroy
  has_many :events, :dependent => :destroy
  belongs_to :project
  belongs_to :client
  validates_presence_of :client, :date, :currency, :project_id, :unless => Proc.new {|i| i.type == "ReceivedInvoice" }
  validates_inclusion_of :currency, :in  => Money::Currency::TABLE.collect {|k,v| v[:iso_code] }, :unless => Proc.new {|i| i.type == "ReceivedInvoice" }
  validate :payment_method_requirements, :unless => Proc.new {|i| i.type == "ReceivedInvoice" }

  accepts_nested_attributes_for :invoice_lines,
    :allow_destroy => true,
    :reject_if => proc { |attributes| attributes.all? { |_, value| value.blank? } }
  validates_associated :invoice_lines

  composed_of :import,
    :class_name => "Money",
    :mapping => [%w(import_in_cents cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) }

  def initialize(attributes=nil)
    super
    self.discount_percent ||= 0
    self.currency ||= self.client.currency rescue nil
    self.currency ||= self.company.currency rescue nil
    self.currency ||= Setting.plugin_haltr['default_currency']
    self.payment_method ||= 1
  end

  def currency=(v)
    write_attribute(:currency,v.upcase)
    invoice_lines.each do |il|
      il.currency=v.upcase
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
    if tax_percent
      subtotal * (tax_percent / 100.0)
    else
      Money.new(0,currency)
    end
  end

  def persontypecode
    if withholding_tax_percent > 0
      "F" # Fisica
    else
      "J" # Juridica
    end
  end

  def withholding_tax
    if self.apply_withholding_tax
      subtotal * (withholding_tax_percent / 100.0)
    else
      0.to_money(currency)
    end
  end

  def withholding_tax_percent
    if apply_withholding_tax
      company.withholding_tax_percent.nil? ? 0 : company.withholding_tax_percent
    else
      0
    end
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

  def pdf_name
    "factura-#{number.gsub('/','')}.pdf" rescue "factura-___.pdf"
  end

  def recipients
    Person.find(:all,:order=>'last_name ASC',:conditions => ["client_id = ? AND invoice_recipient = ?", client, true])
  end

  def terms_description
    terms_object.description
  end

  def payment_method_string
    if international?
      if debit?
        iban = client.iban || ""
        bic  = client.bic || ""
        "#{l(:debit_str)} (#{bic}) #{iban[0..3]} #{iban[4..7]} #{iban[8..11]} **** **** #{iban[20..23]}"
      elsif transfer?
        iban = company.iban || ""
        bic  = company.bic || ""
        "#{l(:transfer_str)} (#{bic}) #{iban[0..3]} #{iban[4..7]} #{iban[8..11]} #{iban[12..15]} #{iban[16..19]} #{iban[20..23]}"
      else
        l(:cash_str)
      end
    else
      if debit?
        ba = client.bank_account || ""
        "#{l(:debit_str)} #{ba[0..3]} #{ba[4..7]} ** ******#{ba[16..19]}"
      elsif transfer?
        ba = company.bank_account ||= ""
        "#{l(:transfer_str)} #{ba[0..3]} #{ba[4..7]} #{ba[8..9]} #{ba[10..19]}"
      else
        l(:cash_str)
      end
    end
  end

  def self.payment_methods
    [[l("cash"), 1],[l("debit"), 2],[l("transfer"), 4]]
  end

  def debit?
    payment_method == PAYMENT_DEBIT
  end

  def transfer?
    payment_method == PAYMENT_TRANSFER
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

  def international?
    # use Client.find to reload client info, sometimnes changed with ajax
    c = Client.find client_id
    company.country != c.country
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

  def payment_method_requirements
    if debit? and !international?
      c = Client.find client_id
      errors.add(:base, ("#{l(:field_payment_method)} (#{l(:debit)}) #{l(:requires_client_bank_account)}")) if c.bank_account.blank?
    elsif debit? and international?
      c = Client.find client_id
      errors.add(:base, ("#{l(:field_payment_method)} (#{l(:debit)}) #{l(:requires_client_iban_bic)}")) if c.iban.blank? or c.bic.blank?
    elsif transfer? and !international?
      errors.add(:base, ("#{l(:field_payment_method)} (#{l(:transfer)}) #{l(:requires_company_bank_account)}")) if company.bank_account.blank?
    elsif transfer? and international?
      errors.add(:base, ("#{l(:field_payment_method)} (#{l(:transfer)}) #{l(:requires_company_iban_bic)}")) if company.iban.blank? or company.bic.blank?
    end
  end

  def invoice_must_have_lines
    if invoice_lines.empty? or invoice_lines.all? {|i| i.marked_for_destruction?}
      errors.add(:base, "#{l(:label_invoice)} #{l(:must_have_lines)}")
    end
  end

end
