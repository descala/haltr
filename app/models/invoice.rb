class Invoice < ActiveRecord::Base

  unloadable

  # 1 - cash (al comptat)
  # 2 - debit (rebut domiciliat)
  # 4 - transfer (transferència)
  PAYMENT_CASH = 1
  PAYMENT_DEBIT = 2
  PAYMENT_TRANSFER = 4

  # Default tax %
  TAX = 18

  has_many :invoice_lines, :dependent => :destroy
  has_many :events, :dependent => :destroy
  belongs_to :project
  belongs_to :client
  validates_presence_of :client, :date, :currency, :project_id
  validates_inclusion_of :currency, :in  => Money::Currency::TABLE.collect {|k,v| v[:iso_code] }

  accepts_nested_attributes_for :invoice_lines,
    :allow_destroy => true,
    :reject_if => proc { |attributes| attributes.all? { |_, value| value.blank? } }
  validates_associated :invoice_lines
  validate :payment_method_requirements

  composed_of :import,
    :class_name => "Money",
    :mapping => [%w(import_in_cents cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) }

  def initialize(attributes=nil)
    super
    self.discount_percent ||= 0
    self.currency ||= self.client.currency rescue nil
    self.currency ||= self.company.currency rescue nil
    self.currency ||= Money.default_currency.iso_code
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

  def terms_description
    terms_object.description
  end

  def payment_method_string
    if debit? and !client.bank_account.blank?
      ba = client.bank_account rescue ""
      ba ||= ""
      "#{l(:debit_str)} #{ba[0..3]} #{ba[4..7]} ** ******#{ba[16..19]}"
    elsif transfer?
      ba = company.bank_account rescue ""
      ba ||= ""
      "#{l(:transfer_str)} #{ba[0..3]} #{ba[4..7]} #{ba[8..9]} #{ba[10..19]}"
    else
      l(:cash_str)
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

  def payment_method_code
    if payment_method < 10
      "0#{payment_method}"
    else
      payment_method.to_s
    end
  end

  def <=>(oth)
    self.number <=> oth.number
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
    if debit?
      errors.add(:base, ("#{l(:field_payment_method)} (#{l(:debit)}) #{l(:requires_client_bank_account)}")) if client.bank_account.blank?
    elsif transfer?
      errors.add(:base, ("#{l(:field_payment_method)} (#{l(:transfer)}) #{l(:requires_company_bank_account)}")) if company.bank_account.blank?
    end
  end

end
