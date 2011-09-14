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

  has_many :invoice_lines, :dependent => :destroy
  has_many :events, :dependent => :destroy
  has_many :taxes, :through => :invoice_lines
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
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money::Currency.new(Setting.plugin_haltr['default_currency'])) }

  composed_of :total,
    :class_name => "Money",
    :mapping => [%w(total_in_cents cents), %w(currency currency_as_string)],
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

  def subtotal_without_discount(tax_type=nil)
    amount = Money.new(0,currency)
    invoice_lines.each do |line|
      next if line.destroyed?
      amount += line.total if tax_type.nil? or line.has_tax?(tax_type)
    end
    amount
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
      subtotal_without_discount(tax_type) * (discount_percent / 100.0)
    else
      Money.new(0,currency)
    end
  end

  def discount_without_expenses
    discount - ( expenses_total - total_general_surcharges )
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

  # cost de les taxes (Money)
  def tax_amount(tax_type=nil)
    t = Money.new(0,currency)
    invoice_lines.each do |il|
      t += il.tax_amount(tax_type)
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

  def taxes_uniq
    taxes.find :all, :group=> 'name,percent'
  end

  def tax_names
    taxes.collect {|tax| tax.name }.uniq
  end

  def taxes_hash
    th = company.taxes_hash
    taxes_uniq.each do |t|
      th[t.name] = [] unless th[t.name]
      th[t.name] << t.percent unless th[t.name].include? t.percent
    end
    th
  end

  def taxes_outputs
    taxes.find(:all, :group => 'name,percent', :conditions => "percent > 0")
  end

  def total_tax_outputs
    t = Money.new(0,currency)
    taxes_outputs.each do |tax|
      t += tax_amount(tax)
    end
    t
  end

  def taxes_withheld
    taxes.find(:all, :group => 'name,percent', :conditions => "percent < 0")
  end

  def total_taxes_withheld
    t = Money.new(0,currency)
    taxes_withheld.each do |tax|
      t += tax_amount(tax)
    end
    # here we have negative amount, pass it to positive (what facturae template expects)
    t * -1
  end

  def expenses
    invoice_lines.collect { |line|
      line if line.expenses?
    }.compact
  end

  def expenses_total
    t = Money.new(0,currency)
    expenses.each do |line|
      t += line.total
    end
    t
  end

  def total_general_surcharges
    t = Money.new(0,currency)
    expenses.each do |line|
      t += line.taxable_base
    end
    t
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
