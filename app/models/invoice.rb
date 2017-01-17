class Invoice < ActiveRecord::Base

  include HaltrHelper
  include Haltr::FloatParser
  include Haltr::PaymentMethods
  float_parse :fa_import, :discount_amount, :discount_percent, :exchange_rate

  audited except: [:import_in_cents, :total_in_cents,
                   :state, :has_been_read, :id, :original]
  has_associated_audits
  # do not remove, with audit we need to make the other attributes accessible
  attr_protected :created_at, :updated_at

  # remove non-utf8 characters from those fields:
  TO_UTF_FIELDS = %w(extra_info)

  has_many :invoice_lines, -> {order 'position is NULL, position ASC'}, dependent: :destroy
  has_many :events, -> {order :created_at}
  #has_many :taxes, :through => :invoice_lines
  belongs_to :project, :counter_cache => true
  belongs_to :client
  # an invoice can have one sustitutive amend
  belongs_to :amend, :class_name => "Invoice", :foreign_key => 'amend_id'
  has_one :amend_of, :class_name => "Invoice", :foreign_key => 'amend_id'
  # an invoice can have several partial amends
  has_many :partial_amends, class_name: 'Invoice', foreign_key: 'partially_amended_id'
  belongs_to :partial_amend_of, class_name: 'Invoice', foreign_key: 'partially_amended_id'

  belongs_to :bank_info
  belongs_to :quote
  has_many :comments, -> {order :created_on}, :as => :commented, :dependent => :delete_all
  belongs_to :client_office
  belongs_to :company_office
  has_one :order, dependent: :nullify
  validates_inclusion_of :client_office_id, in: [nil], unless: Proc.new {|i|
    i.client and i.client.client_offices.any? {|o| o.id == i.client_office_id }
  }

  validates_presence_of :date, :currency, :project_id, :unless => Proc.new {|i| i.type == "ReceivedInvoice" }
  validates :date, format: { with: /\A[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}\z/ }
  validates_presence_of :client, :unless => Proc.new {|i| %w(Quote ReceivedInvoice).include? i.type }
  validates_inclusion_of :currency, :in  => Money::Currency.table.collect {|k,v| v[:iso_code] }, :unless => Proc.new {|i| i.type == "ReceivedInvoice" }
  validates_numericality_of :charge_amount_in_cents, :allow_nil => true
  validates_numericality_of :payments_on_account_in_cents, :allow_nil => true
  validates_numericality_of :amounts_withheld_in_cents, :allow_nil => true
  validates_numericality_of :exchange_rate, :allow_blank => true
  validates_format_of :exchange_rate, with: /\A-?[0-9]+(\.[0-9]{1,2}|)\z/,
    :allow_blank => true

  before_save :fields_to_utf8
  after_create :increment_counter
  before_destroy :decrement_counter
  before_save :call_before_save_hook
  before_validation :set_lines_order

  accepts_nested_attributes_for :invoice_lines,
    :allow_destroy => true,
    :reject_if => :all_blank
  validates_associated :invoice_lines

  validate :bank_info_belongs_to_self
  validate :has_all_fields_required_by_external_company
  validate :fa_taxcode_requires_other_fa_fields

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

  composed_of :payments_on_account,
    :class_name => "Money",
    :mapping => [%w(payments_on_account_in_cents cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money::Currency.new(Setting.plugin_haltr['default_currency'])) }

  composed_of :amounts_withheld,
    :class_name => "Money",
    :mapping => [%w(amounts_withheld_in_cents cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money::Currency.new(Setting.plugin_haltr['default_currency'])) }

  after_initialize :set_default_values

  acts_as_attachable :view_permission => :use_invoice_attachments,
                   :delete_permission => :use_invoice_attachments,
                           :after_add => :attachment_added,
                       :before_remove => :attachment_removed

  def set_default_values
    self.currency ||= self.client.currency rescue nil
    self.currency ||= self.company.currency rescue nil
    self.currency ||= Setting.plugin_haltr['default_currency']
  end

  def currency=(v)
    return unless v
    write_attribute(:currency,v.upcase)
  end

  def original=(s)
    write_attribute(:original, Haltr::Utils.compress(s))
  end

  def original
    Haltr::Utils.decompress(read_attribute(:original))
  end

  def lines_with_tax(tax_type)
    invoice_lines.collect {|line|
      next if line.destroyed? or line.marked_for_destruction?
      line if tax_type.nil? or line.has_tax?(tax_type)
    }.compact
  end

  # Importe bruto.
  # Suma total de importes brutos de los detalles de la factura
  def gross_subtotal(tax_type=nil)
    Haltr::Utils.to_money(lines_with_tax(tax_type).collect { |line|
      Haltr::Utils.to_money(line.gross_amount, currency, company.rounding_method)
    }.sum, currency, company.rounding_method)
  end

  # only used in svefaktura: LineExtensionTotalAmount
  def subtotal_without_discount(tax_type=nil)
    gross_subtotal(tax_type) + charge_amount
  end

  # TotalGrossAmountBeforeTaxes
  # Total importe bruto antes de impuestos.
  # TotalGrossAmount - TotalGeneralDiscounts + TotalGeneralSurcharges
  def subtotal(tax_type=nil)
    gross_subtotal(tax_type) - discount_amount(tax_type) + charge_amount
  end

  def pdf_name
    "#{self.pdf_name_without_extension}.pdf" rescue "factura-___.pdf"
  end

  def xml_name
    "#{self.pdf_name_without_extension}.xml" rescue "factura-___.xml"
  end

  def pdf_name_without_extension
    "#{l(:label_invoice)}-#{number.gsub('/','')}" rescue "factura-___"
  end

  def recipient_emails
    unless client_email_override.blank?
      client_email_override.split(/[,; ]/)
    else
      client.recipient_emails
    end
  end

  def terms_description
    terms_object.description
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
    self.project.company rescue nil
  end

  def company_name
    project.company.name rescue nil
  end

  def line_descriptions_txt
    invoice_lines.collect do |line|
      " * #{line.description}"
    end.join("\n")
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

  def is_amend?
    false # Only IssuedInvoices can be an amend
  end

  # round_before_sum:
  #   true:  Arrodonir IVA de cada línia i després sumar
  #   false: Sumar els IVA de les línies i després arrodonir
  #TODO: ull amb round_before_sum hi ha facturae que no valida!
  # cost de les taxes (Money)
  def tax_amount(tax_type=nil)
    t = Money.new(0,currency)
    if tax_type.nil?
      taxes_uniq.each do |tax|
        # check round_before_sum setting from company #5324
        if company and company.round_before_sum
          # sum([round(price) x tax])
          taxes_imports = lines_with_tax(tax).collect {|line|
            price = Haltr::Utils.to_money(line.gross_amount, currency, company.rounding_method)
            discount = Haltr::Utils.to_money((line.total_cost*(discount_percent / 100.0)),currency,company.rounding_method)
            (price - discount)*(tax.percent / 100.0)
          }
          t += taxes_imports.sum
        else
          # sum(price) x tax
          t += taxable_base(tax) * (tax.percent / 100.0)
        end
      end
    else
      # check round_before_sum setting from company #5324
      if company and company.round_before_sum
        # sum([round(price) x tax])
        t += lines_with_tax(tax_type).collect {|line|
          price = Haltr::Utils.to_money(line.gross_amount, currency, company.rounding_method)
          discount = Haltr::Utils.to_money((line.total_cost*(discount_percent / 100.0)),currency, company.rounding_method)
          (price - discount)*(tax_type.percent / 100.0)
        }.sum
      else
        # sum(price) x tax
        t += taxable_base(tax_type) * (tax_type.percent / 100.0)
      end
    end
    Haltr::Utils.to_money(t, currency, company.rounding_method)
  end

  # Base imponible a precio de mercado
  # Total Importe Bruto + Recargos - Descuentos Globales
  def taxable_base(tax_type=nil)
    Haltr::Utils.to_money(lines_with_tax(tax_type).collect {|line|
      Haltr::Utils.to_money(line.gross_amount, currency, company.rounding_method)
    }.sum, currency, company.rounding_method) - discount_amount(tax_type)
  end

  def discount_amount(tax_type=nil)
    if self[:discount_amount] and self[:discount_amount] != 0
      if tax_type.nil?
        Haltr::Utils.to_money(self[:discount_amount], currency, company.rounding_method)
      else
        # must calculate discount percent to calculate taxable base for a tax_type
        # (issue 5517 note-5)
        gross_subtotal(tax_type) * (discount_percent / 100.0)
      end
    elsif self[:discount_percent] and self[:discount_percent] != 0
      gross_subtotal(tax_type) * (self[:discount_percent] / 100.0)
    else
      Money.new(0, currency)
    end
  end

  def discount_percent
    if self[:discount_percent] and self[:discount_percent] != 0
      self[:discount_percent]
    elsif self[:discount_amount] and self[:discount_amount] != 0 and gross_subtotal.dollars != 0
      (self[:discount_amount].to_f * 100 / gross_subtotal.dollars).round(2)
    else
      0
    end
  end

  def discount
    if discount_type == '€'
      discount_amount
    else
      discount_percent
    end
  end

  def discount_type
    if self[:discount_amount] and self[:discount_amount] != 0
      '€'
    else
      '%'
    end
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
      tt << tax unless tt.include? tax or tax.marked_for_destruction?
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
    tt = []
    (company.taxes + taxes_uniq).each do |t|
      tt << t unless tt.include?(t)
    end
    tt
  end

  def taxes_outputs
    #taxes.where("percent >= 0").group('name,percent')
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
    #taxes.where("percent < 0").group('name,percent')
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
    if value.to_s =~ /^[0-9,.']*$/
      value = Money.parse(value)
      write_attribute :charge_amount_in_cents, value.cents
    else
      # this + validates_numericality_of will raise an error if not a number
      write_attribute :charge_amount_in_cents, value
    end
  end

  def payments_on_account=(value)
    if value.to_s =~ /^[-0-9,.']*$/
      value = Money.parse(value)
      write_attribute :payments_on_account_in_cents, value.cents
    else
      # this + validates_numericality_of will raise an error if not a number
      write_attribute :payments_on_account_in_cents, value
    end
  end

  def amounts_withheld=(value)
    if value.to_s =~ /^[-0-9,.']*$/
      value = Money.parse(value)
      write_attribute :amounts_withheld_in_cents, value.cents
    else
      # this + validates_numericality_of will raise an error if not a number
      write_attribute :amounts_withheld_in_cents, value
    end
  end

  def issuer_transaction_reference=(value)
    invoice_lines.each do |line|
      line.issuer_transaction_reference=value
    end
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
    return company.default_tax_code_for(tax_name) if new_record?
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
  #
  def taxes_by_category(positive: true)
    cts = {}
    t = positive ? taxes_outputs : taxes_withheld
    t.each do |tax|
      cts[tax.name] = {}
    end
    t.each do |tax|
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

  def tax_comments
    tc = self.taxes.collect do |tax|
      tax.comment unless tax.comment.blank?
    end.compact
    tc.delete('')
    tc.uniq!
    tc.compact.join('. ')
  end

  def legal_literals_plus_tax_comments
    str = legal_literals.to_s
    str += ' ' unless str.blank?
    str += tax_comments
    str
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

  def modified_since_created?
    return false if new_record?
    updated_at > created_at
  end

  # has factoring assignment data?
  def has_factoring_data?
    %w(fa_person_type fa_residence_type fa_taxcode).reject { |attr|
      self.send(attr).blank? or self.send(attr) == 0
    }.size == 3
  end

  def fa_taxcode_requires_other_fa_fields
    if fa_taxcode.present?
      errors.add(:fa_person_type, :blank) if fa_person_type.blank?
      errors.add(:fa_residence_type, :blank) if fa_residence_type.blank?
    end
  end

  def self.create_from_xml(raw_invoice,user_or_company,md5,transport,from=nil,issued=nil,keep_original=true,validate=true,override_original=nil,override_original_name=nil)

    file_name = nil
    if raw_invoice.respond_to? :filename             # Mail::Part
      file_name = raw_invoice.filename
    elsif raw_invoice.respond_to? :original_filename # UploadedFile
      file_name = raw_invoice.original_filename
    elsif raw_invoice.respond_to? :path              # File (tests)
      file_name = File.basename(raw_invoice.path)
    else
      file_name = "invoice.xml"
    end

    if raw_invoice.is_a? String
      raw_xml = raw_invoice
    else
      raw_xml = raw_invoice.read
    end
    doc = Nokogiri::XML(raw_xml)
    if doc.child and doc.child.name == "StandardBusinessDocument"
      doc = Haltr::Utils.extract_from_sbdh(doc)
    end
    doc_no_namespaces = doc.dup.remove_namespaces!
    facturae_version  = doc.at_xpath("//FileHeader/SchemaVersion")
    ubl_version       = doc_no_namespaces.at_xpath("//Invoice/UBLVersionID")
    # invoice_format should match format in config/channels.yml
    if facturae_version
      # facturae30 facturae31 facturae32
      invoice_format  = "facturae#{facturae_version.text.gsub(/[^\d]/,'')}"
      logger.info "Creating invoice from xml - format is FacturaE #{facturae_version.text}. time=#{Time.now}"
    elsif ubl_version
      #TODO: biiubl20 efffubl oioubl20 pdf peppolubl20 peppolubl21 svefaktura
      invoice_format  = "ubl#{ubl_version.text}"
      logger.info "Creating invoice from xml - format is UBL #{ubl_version.text}. time=#{Time.now}"
    else
      logger.info "Creating invoice from xml - unknown format. time=#{Time.now}"
      raise "Unknown format"
    end

    xpaths         = Haltr::Utils.xpaths_for(invoice_format)
    seller_taxcode = Haltr::Utils.get_xpath(doc,xpaths[:seller_taxcode])
    if ubl_version
      seller_taxcode ||= Haltr::Utils.get_xpath(doc,xpaths[:seller_taxcode2])
      seller_taxcode ||= Haltr::Utils.get_xpath(doc,xpaths[:seller_taxcode3])
    end
    buyer_taxcode  = Haltr::Utils.get_xpath(doc,xpaths[:buyer_taxcode])
    if buyer_taxcode.nil? and ubl_version
      buyer_taxcode  = Haltr::Utils.get_xpath(doc,xpaths[:buyer_taxcode_id])
      if buyer_taxcode.nil?
        buyer_taxcode  = Haltr::Utils.get_xpath(doc,xpaths[:buyer_endpoint_id])
      end
    end
    currency       = Haltr::Utils.get_xpath(doc,xpaths[:currency])
    exchange_rate  = Haltr::Utils.get_xpath(doc,xpaths[:exchange_rate])
    exchange_date  = Haltr::Utils.get_xpath(doc,xpaths[:exchange_date])
    # invoice data
    invoice_number   = Haltr::Utils.get_xpath(doc,xpaths[:invoice_number])
    invoice_series   = Haltr::Utils.get_xpath(doc,xpaths[:invoice_series])
    invoice_date     = Haltr::Utils.get_xpath(doc,xpaths[:invoice_date])
    tax_point_date   = Haltr::Utils.get_xpath(doc,xpaths[:tax_point_date])
    i_period_start   = Haltr::Utils.get_xpath(doc,xpaths[:invoicing_period_start])
    i_period_end     = Haltr::Utils.get_xpath(doc,xpaths[:invoicing_period_end])
    invoice_total    = Haltr::Utils.get_xpath(doc,xpaths[:invoice_total])
    invoice_import   = Haltr::Utils.get_xpath(doc,xpaths[:invoice_import])
    invoice_due_date = Haltr::Utils.get_xpath(doc,xpaths[:invoice_due_date])
    discount_percent = Haltr::Utils.get_xpath(doc,xpaths[:discount_percent])
    discount_amount  = Haltr::Utils.get_xpath(doc,xpaths[:discount_amount])
    #total_gross      = Haltr::Utils.get_xpath(doc,xpaths[:invoice_totalgross])
    discount_text    = Haltr::Utils.get_xpath(doc,xpaths[:discount_text])
    extra_info       = Haltr::Utils.get_xpath(doc,xpaths[:extra_info])
    charge           = Haltr::Utils.get_xpath(doc,xpaths[:charge])
    charge_reason    = Haltr::Utils.get_xpath(doc,xpaths[:charge_reason])
    accounting_cost  = Haltr::Utils.get_xpath(doc,xpaths[:accounting_cost])
    payments_on_account = Haltr::Utils.get_xpath(doc,xpaths[:payments_on_account]) || 0
    amounts_withheld_reason = Haltr::Utils.get_xpath(doc,xpaths[:amounts_withheld_r])
    amounts_withheld = Haltr::Utils.get_xpath(doc,xpaths[:amounts_withheld]) || 0
    amend_of         = Haltr::Utils.get_xpath(doc,xpaths[:amend_of])
    #TODO: serie
    _amend_of_serie  = Haltr::Utils.get_xpath(doc,xpaths[:amend_of_serie])
    amend_type       = Haltr::Utils.get_xpath(doc,xpaths[:amend_type])
    amend_reason     = Haltr::Utils.get_xpath(doc,xpaths[:amend_reason])
    party_id         = Haltr::Utils.get_xpath(doc,xpaths[:party_id])
    legal_literals   = Haltr::Utils.get_xpath(doc,xpaths[:legal_literals])


    # factoring assignment data
    fa_person_type    = Haltr::Utils.get_xpath(doc,xpaths[:fa_person_type])
    fa_residence_type = Haltr::Utils.get_xpath(doc,xpaths[:fa_residence_type])
    fa_taxcode        = Haltr::Utils.get_xpath(doc,xpaths[:fa_taxcode])
    fa_name           = Haltr::Utils.get_xpath(doc,xpaths[:fa_name])
    fa_address        = Haltr::Utils.get_xpath(doc,xpaths[:fa_address])
    fa_postcode       = Haltr::Utils.get_xpath(doc,xpaths[:fa_postcode])
    fa_town           = Haltr::Utils.get_xpath(doc,xpaths[:fa_town])
    fa_province       = Haltr::Utils.get_xpath(doc,xpaths[:fa_province])
    fa_country        = Haltr::Utils.get_xpath(doc,xpaths[:fa_country])
    fa_info           = Haltr::Utils.get_xpath(doc,xpaths[:fa_info])
    fa_duedate        = Haltr::Utils.get_xpath(doc,xpaths[:fa_duedate])
    fa_import         = Haltr::Utils.get_xpath(doc,xpaths[:fa_import])
    fa_iban           = Haltr::Utils.get_xpath(doc,xpaths[:fa_iban])
    fa_bank_code      = Haltr::Utils.get_xpath(doc,xpaths[:fa_bank_code])
    fa_clauses        = Haltr::Utils.get_xpath(doc,xpaths[:fa_clauses])
    fa_payment_method = Haltr::Utils.get_xpath(doc,xpaths[:fa_payment_method])

    invoice, client_role, company, user = nil

    # prevent nil/blank taxcodes, since it will match all on 'like' conditions
    seller_taxcode = 'empty_seller_taxcode' if seller_taxcode.blank?
    buyer_taxcode  = 'empty_buyer_taxcode'  if buyer_taxcode.blank?

    if user_or_company.is_a? Company
      # used in haltr_mail_handler
      company = user_or_company
    else
      # used invoices#import
      user = user_or_company
      from = user.name
      company   = user.companies.where('taxcode like ?', "%#{seller_taxcode}").first
      company ||= user.companies.where('? like concat("%", taxcode)', seller_taxcode).first
      company ||= user.companies.where('taxcode like ?', "%#{buyer_taxcode}").first
      company ||= user.companies.where('? like concat("%", taxcode)', buyer_taxcode).first
    end

    if company.nil?
      raise I18n.t :taxcodes_does_not_belong_to_self,
        :tcs => "#{buyer_taxcode} - #{seller_taxcode}",
        :tc  => user.companies.collect{|c|c.taxcode}.join(',')
    end

    invoice_total = Haltr::Utils.to_money(invoice_total, currency, company.rounding_method)

    # check if it is a received_invoice or an issued_invoice.
    if company.taxcode.include?(buyer_taxcode) or buyer_taxcode.include?(company.taxcode)
      invoice = ReceivedInvoice.new(project: company.project)
      client_role= "seller"
    elsif company.taxcode.include?(seller_taxcode) or seller_taxcode.include?(company.taxcode)
      invoice = IssuedInvoice.new(project: company.project)
      client_role = "buyer"
    else
      raise I18n.t :taxcodes_does_not_belong_to_self,
        :tcs => "#{buyer_taxcode} - #{seller_taxcode}",
        :tc  => company.taxcode
    end

    # amend invoices
    if amend_of
      #TODO: comprovar amend_of_serie
      raise "Cannot amend received invoices" if invoice.is_a? ReceivedInvoice
      amended = company.project.issued_invoices.where(number: amend_of).last
      if amended and amend_type == '01'
        invoice.amend_of = amended
      elsif amended and amend_type == '02'
        invoice.partial_amend_of = amended
      #elsif amended
        #TODO 03 and 04 not yet supported
      else
        # importing amend invoice for an unexisting invoice, assign self id as
        # amended as a dirty hack
        if amend_type == '02'
          invoice.partial_amend_of = invoice
        else
          invoice.amend_of = invoice
        end
      end
      invoice.amended_number = amend_of
      invoice.amend_reason = amend_reason
    end

    # if passed issued param, check if it should be an IssuedInvoice or a ReceivedInvoice
    unless issued.nil?
      if !issued and invoice.is_a? IssuedInvoice
        raise l(:import_issued_from_received)
      elsif issued and invoice.is_a? ReceivedInvoice
        raise l(:import_received_from_issued)
      end
    end

    # get client data from imported invoice
    client_taxcode     = client_role == "seller" ? seller_taxcode : buyer_taxcode
    client_name        = Haltr::Utils.get_xpath(doc,xpaths["#{client_role}_name"]) ||
      Haltr::Utils.get_xpath(doc,xpaths["#{client_role}_name2"])
    client_address     = Haltr::Utils.get_xpath(doc,xpaths["#{client_role}_address"])
    client_province    = Haltr::Utils.get_xpath(doc,xpaths["#{client_role}_province"])
    client_country     = Haltr::Utils.get_xpath(doc,xpaths["#{client_role}_countrycode"])
    client_website     = Haltr::Utils.get_xpath(doc,xpaths["#{client_role}_website"])
    client_email       = Haltr::Utils.get_xpath(doc,xpaths["#{client_role}_email"])
    client_cp_city     = Haltr::Utils.get_xpath(doc,xpaths["#{client_role}_cp_city"]) ||
      Haltr::Utils.get_xpath(doc,xpaths["#{client_role}_cp_city2"])
    client_postalcode  = client_cp_city.split(" ").first rescue ""
    client_city        = client_cp_city.gsub(/^#{client_postalcode} ?/,'') rescue ""
    if client_postalcode.blank?
      client_postalcode  = Haltr::Utils.get_xpath(doc,xpaths["#{client_role}_cp"])
    end

    client_language = User.current.language
    client_language = 'es' if client_language.blank?
    default_channel = 'paper'
    if ExportChannels.available? 'link_to_pdf_by_mail'
      default_channel = 'link_to_pdf_by_mail'
    end

    invoice.client, invoice.client_office = Haltr::Utils.client_from_hash(
      :taxcode        => client_taxcode.to_s.gsub(/\s/,''),
      :name           => client_name,
      :address        => client_address,
      :province       => client_province,
      :country        => client_country,
      :website        => client_website,
      :email          => client_email,
      :postalcode     => client_postalcode,
      :city           => client_city,
      :currency       => currency,
      :project        => company.project,
      :invoice_format => default_channel,
      :language       => client_language
    )

    # if it is an issued invoice, and
    #    the client already exists, and
    #    this client has different email than this invoice, then
    # save the email address to the invoice (overrides client email
    if client_role == "buyer" and invoice.client
      client_email = Haltr::Utils.get_xpath(doc,xpaths["buyer_email"])
      if client_email and client_email != invoice.client.email
        invoice.client_email_override = client_email
      end
    end

    doc.xpath(xpaths[:dir3s]).each do |line|
      role = Haltr::Utils.get_xpath(line, xpaths[:dir3_role])
      code = Haltr::Utils.get_xpath(line, xpaths[:dir3_code]).gsub(/ /,'') rescue nil
      case role
      when '01'
        invoice.oficina_comptable  = code
        invoice.oficina_comptable_name = Haltr::Utils.get_xpath(line, xpaths[:dir3_name])
      when '02'
        invoice.organ_gestor       = code
      when '03'
        invoice.unitat_tramitadora = code
        invoice.unitat_tramitadora_name = Haltr::Utils.get_xpath(line, xpaths[:dir3_name])
      when '04'
        invoice.organ_proponent    = code
      when nil
        # https://www.ingent.net/issues/6074 (Unitat contractació / SEF)
        invoice.unitat_contractacio = code
      else
        # unknown role
      end
      # save unknown Dir3 entities
      Dir3Entity.new_from_hash({
        code: code,
        name:       Haltr::Utils.get_xpath(line, xpaths[:dir3_name]),
        address:    Haltr::Utils.get_xpath(line, xpaths[:dir3_address]),
        postalcode: Haltr::Utils.get_xpath(line, xpaths[:dir3_postcode]),
        city:       Haltr::Utils.get_xpath(line, xpaths[:dir3_town]),
        province:   Haltr::Utils.get_xpath(line, xpaths[:dir3_province]),
        country:    Haltr::Utils.get_xpath(line, xpaths[:dir3_country])
      }, invoice.client.taxcode, role)
    end

    original = nil
    original_format = nil
    if override_original.present? and override_original_name.present?
      original  = Haltr::Utils.decompress(override_original)
      file_name = override_original_name
      # TODO: support override_original other than PDF
      original_format = 'pdf'
    elsif keep_original
      original = raw_xml
    end

    # there are several Discounts, sum them
    if discount_amount =~ / /
      discount_amount = discount_amount.split.collect {|a| Haltr::Utils.float_parse(a) }.sum
    end
    if discount_percent =~ / /
      discount_percent = discount_percent.split.collect {|a| Haltr::Utils.float_parse(a) }.sum
    end

    invoice.assign_attributes(
      :number           => invoice_number,
      :series_code      => invoice_series,
      :date             => invoice_date,
      :tax_point_date   => tax_point_date,
      :invoicing_period_start => i_period_start,
      :invoicing_period_end   => i_period_end,
      :total            => invoice_total,
      :currency         => currency,
      :exchange_rate    => exchange_rate,
      :exchange_date    => exchange_date,
      :import           => Haltr::Utils.to_money(invoice_import, currency, company.rounding_method),
      :due_date         => invoice_due_date,
      :project          => company.project,
      :terms            => "custom",
      :invoice_format   => original_format || invoice_format, # facturae3.2, ubl21...
      :transport        => transport,      # email, uploaded
      :from             => from,           # u@mail.com, User Name...
      :md5              => md5,
      :original         => original,
      :discount_amount  => discount_amount,
      :discount_percent => discount_percent,
      :discount_text    => discount_text,
      :extra_info       => extra_info,
      :charge_amount    => charge,
      :charge_reason    => charge_reason,
      :accounting_cost  => accounting_cost,
      :payments_on_account => Haltr::Utils.to_money(payments_on_account, currency, company.rounding_method),
      :amounts_withheld_reason  => amounts_withheld_reason,
      :amounts_withheld  => Haltr::Utils.to_money(amounts_withheld, currency, company.rounding_method),
      :fa_person_type    => fa_person_type,
      :fa_residence_type => fa_residence_type,
      :fa_taxcode        => fa_taxcode,
      :fa_name           => fa_name,
      :fa_address        => fa_address,
      :fa_postcode       => fa_postcode,
      :fa_town           => fa_town,
      :fa_province       => fa_province,
      :fa_country        => (SunDawg::CountryIsoTranslater.translate_standard(fa_country,"alpha3","alpha2").downcase rescue nil),
      :fa_info           => fa_info,
      :fa_duedate        => fa_duedate,
      :fa_import         => fa_import,
      :fa_payment_method => fa_payment_method,
      :fa_iban           => fa_iban,
      :fa_bank_code      => fa_bank_code,
      :fa_clauses        => fa_clauses,
      :party_identification => party_id,
      :legal_literals    => legal_literals,
      :file_name         => file_name
    )

    xml_payment_method = Haltr::Utils.get_xpath(doc,xpaths[:payment_method])
    if invoice_format =~ /facturae/
      invoice.payment_method = Haltr::Utils.payment_method_from_facturae(xml_payment_method)
    else # ubl
      invoice.payment_method = Haltr::Utils.payment_method_from_ubl(xml_payment_method)
    end

    # bank info
    if invoice.debit?
      invoice.parse_xml_bank_info(doc.xpath(xpaths[:to_be_debited]).to_s)
    elsif invoice.transfer?
      invoice.parse_xml_bank_info(doc.xpath(xpaths[:to_be_credited]).to_s)
    end
    invoice.payment_method_text = Haltr::Utils.get_xpath(doc,xpaths[:payment_method_text])

    # invoice lines
    doc.xpath(xpaths[:invoice_lines]).to_enum.with_index(1) do |line,i|

      line_delivery_note_number = nil
      # delivery_notes
      line.xpath(xpaths[:delivery_notes]).each do |dn|
        line_delivery_note_number ||= Haltr::Utils.get_xpath(dn,xpaths[:delivery_note_num])
      end

      unit = Haltr::Utils.get_xpath(line,xpaths[:line_unit])
      InvoiceLine::UNIT_CODES.each do |haltr_id, units|
        if units[:facturae] == unit
          unit = haltr_id
          break
        end
        unit = InvoiceLine::OTHER if unit.present?
      end

      il = InvoiceLine.new(
             :position     => i,
             :quantity     => Haltr::Utils.get_xpath(line,xpaths[:line_quantity]),
             :description  => Haltr::Utils.get_xpath(line,xpaths[:line_description]),
             :price        => Haltr::Utils.get_xpath(line,xpaths[:line_price]),
             :unit         => unit,
             :article_code => Haltr::Utils.get_xpath(line,xpaths[:line_code]),
             :notes        => Haltr::Utils.get_xpath(line,xpaths[:line_notes]),
             :issuer_transaction_reference => Haltr::Utils.get_xpath(line,xpaths[:i_transaction_ref]),
             :sequence_number              => Haltr::Utils.get_xpath(line,xpaths[:sequence_number]),
             :delivery_note_number         => line_delivery_note_number,
             :ponumber                     => Haltr::Utils.get_xpath(line,xpaths[:ponumber]),
             :file_reference               => Haltr::Utils.get_xpath(line,xpaths[:file_reference]),
             :receiver_contract_reference  => Haltr::Utils.get_xpath(line,xpaths[:r_contract_reference])
           )
      if invoice_format =~ /facturae/
        # invoice line taxes. Known taxes are described at config/taxes.yml
        line.xpath(*xpaths[:line_taxes]).each do |line_tax|
          percent = Haltr::Utils.get_xpath(line_tax,xpaths[:tax_percent])
          if line_tax.path =~ /\/TaxesWithheld\//
            percent = "-#{percent}"
          end
          tax = Haltr::TaxHelper.new_tax(
            :format  => invoice_format,
            :id      => Haltr::Utils.get_xpath(line_tax,xpaths[:tax_id]),
            :percent => percent,
            :event_code => Haltr::Utils.get_xpath(line,xpaths[:tax_event_code]),
            :event_reason => Haltr::Utils.get_xpath(line,xpaths[:tax_event_reason])
          )
          il.taxes << tax
          # EquivalenceSurcharges (#5560)
          re_tax_percent = Haltr::Utils.get_xpath(line_tax,xpaths[:tax_surcharge])
          if re_tax_percent.present?
            re_tax = Tax.new(
              :name     => 'RE',
              :percent  => re_tax_percent.to_f,
              :category => tax.category
            )
            il.taxes << re_tax
          end
        end
      else # ubl
        tax_definitions = {}
        doc.xpath(*xpaths[:global_taxes]).each do |gt|
          gt_name     = Haltr::Utils.get_xpath(gt, xpaths[:gtax_name])
          gt_percent  = Haltr::Utils.get_xpath(gt, xpaths[:gtax_percent])
          gt_category = Haltr::Utils.get_xpath(gt, xpaths[:gtax_category])
          tax_definitions[gt_name] ||= {}
          tax_definitions[gt_name][gt_category] = gt_percent
        end
        line.xpath(*xpaths[:line_taxes]).each do |line_tax|
          name     = Haltr::Utils.get_xpath(line_tax, xpaths[:tax_name])
          category = Haltr::Utils.get_xpath(line_tax, xpaths[:tax_category])
          if !tax_definitions.has_key?(name)
            raise "malformed UBL: line has unknown tax #{name}"
          elsif !tax_definitions[name].has_key?(category)
            raise "malformed UBL: line has unknown tax category #{category} for tax #{name}"
          end
          percent  = tax_definitions[name][category]
          tax = Haltr::TaxHelper.new_tax(
            format:   invoice_format,
            name:     name,
            percent:  percent,
            category: category
          )
          il.taxes << tax
        end
      end
      # line discounts
      line_discounts = line.xpath(xpaths[:line_discounts])
      il_disc_percent = 0
      il_disc_amount  = 0
      il_disc_text    = []
      line_discounts.each do |line_disc|
        disc_amount  = Haltr::Utils.get_xpath(line_disc,xpaths[:line_discount_amount])
        disc_percent = Haltr::Utils.get_xpath(line_disc,xpaths[:line_discount_percent])
        disc_text    = Haltr::Utils.get_xpath(line_disc,xpaths[:line_discount_text])
        if disc_amount.present?
          il_disc_amount += BigDecimal.new(disc_amount)
        end
        if disc_percent.present?
          il_disc_percent += BigDecimal.new(disc_percent)
        end
        il_disc_text << disc_text
      end
      il.discount_amount  = il_disc_amount.round(2)
      il.discount_percent = il_disc_percent.round(2)
      il.discount_text = il_disc_text.join('. ')

      # line_charges
      line_charges = line.xpath(xpaths[:line_charges])
      if line_charges.size > 1
        raise "too many charges per line! (#{line_charges.size})"
      elsif line_charges.size == 1
        il.charge = Haltr::Utils.get_xpath(line_charges.first,xpaths[:line_charge])
        il.charge_reason = Haltr::Utils.get_xpath(line_charges.first,xpaths[:line_charge_reason])
      end
      invoice.invoice_lines << il
    end

    # global IRPF, to import only if none of the lines has IRPF #5764
    if invoice.invoice_lines.all? {|l| l.taxes.all? {|tax| tax.percent >= 0 }}
      glob_irpf = Haltr::Utils.get_xpath(doc,xpaths[:glob_irpf])
      if glob_irpf
        glob_irpf = "-#{glob_irpf}"
        glob_irpf_tax = Haltr::TaxHelper.new_tax(
          :format  => invoice_format,
          :id      => '04',
          :percent => glob_irpf
        )
        invoice.invoice_lines.each do |il|
          il.taxes << glob_irpf_tax.dup
        end
      end
    end

    # assign value to invoice field to prevent validation errors on import
    invoice.file_reference = invoice.invoice_lines.first.file_reference
    invoice.ponumber = invoice.invoice_lines.first.ponumber
    invoice.receiver_contract_reference = invoice.invoice_lines.first.receiver_contract_reference

    # attachments
    to_attach = []
    doc.xpath(xpaths[:attachments]).each_with_index do |attach, index|
      data             = Haltr::Utils.get_xpath(attach, xpaths[:attach_data])
      data_compression = Haltr::Utils.get_xpath(attach, xpaths[:attach_compression_algorithm])
      data_format      = Haltr::Utils.get_xpath(attach, xpaths[:attach_format])
      data_encoding    = Haltr::Utils.get_xpath(attach, xpaths[:attach_encoding])

      if data.present?
        data_encoding ||= 'BASE64' if invoice_format =~ /ubl/

        data = case data_encoding
               when 'BASE64'
                 Base64.decode64(data)
               when 'BER'
                 #TODO
               when 'DER'
                 #TODO
               else # NONE
                 data
               end
        data = case data_compression
               when 'ZIP'
                 require 'zip'
                 Zip::InputStream.open(StringIO.new(data)) do |io|
                   _entry = io.get_next_entry
                   io.read
                 end
               when 'GZIP'
                 ActiveSupport::Gzip.decompress(StringIO.new(data))
               else # NONE
                 data
               end
        data_content_type = MIME.check_magics(StringIO.new(data))
        ext = MIME::Types[data_content_type].first.extensions.first rescue data_format

        a = Attachment.new
        a.file = StringIO.new data
        a.author = User.current
        a.description = Haltr::Utils.get_xpath(attach, xpaths[:attach_description])
        a.filename = "facturae_#{invoice.number.gsub('/','')}_#{index+1}.#{ext}"
        to_attach << a
      end
    end
    invoice.attachments = to_attach

    Redmine::Hook.call_hook(:model_invoice_import_before_save, :invoice=>invoice)

    if keep_original and validate
      begin
        invoice.save!
      rescue ActiveRecord::RecordInvalid
        raise invoice.errors.full_messages.join(". ")
      end
    else
      # prevent duplicate invoices #5433
      if !invoice.valid? and invoice.errors.has_key? :number
        raise "#{I18n.t :field_number} #{invoice.errors[:number]}"
      end
      invoice.save(validate: false)
    end

    logger.info "created new invoice with id #{invoice.id} for company #{company.name}. time=#{Time.now}"

    # warn user if calculated total != xml total
    invoice.reload
    if invoice_total != invoice.total
      ImportError.create(
        filename:      (invoice.file_name rescue ""),
        import_errors: I18n.t(:invoice_import_mismatch, original: invoice_total.dollars, calculated: invoice.total.dollars),
        original:      raw_xml,
        project:       company.project,
      )
      Event.create(
        :name    => 'import_errors',
        :notes   => [:invoice_import_mismatch, {original: invoice_total.dollars, calculated: invoice.total.dollars}],
        :invoice => invoice
      )
    end
    return invoice
  rescue
    if company and company.project
      ImportError.create(
        filename:      file_name,
        import_errors: $!.message[0.254],
        original:      raw_xml,
        project:       company.project,
      )
      logger.error "Error creating new invoice for company #{company.name} (#{$!.message}). time=#{Time.now}"
    else
      logger.error "Error creating new invoice (#{$!.message}). time=#{Time.now}"
    end
    raise $!
  end

  def has_original?
    original.present? rescue true
  end

  def send_original?
    Redmine::Hook.call_hook(:model_invoice_send_original, :invoice=>self) != [false] and
      original and !modified_since_created?
  end

  def original_root_namespace
    Nokogiri::XML(original).root.namespace.href
  rescue
    nil
  end

  def parse_xml_bank_info(xml)
    doc          = Nokogiri::XML(xml)
    xpaths       = Haltr::Utils.xpaths_for(invoice_format)
    bank_account = Haltr::Utils.get_xpath(doc,xpaths[:bank_account])
    iban         = Haltr::Utils.get_xpath(doc,xpaths[:iban])
    bic          = Haltr::Utils.get_xpath(doc,xpaths[:bic])
    set_bank_info(bank_account, iban, bic)
  end

  def set_bank_info(bank_account, iban, bic)
    return unless bank_account or iban
    if (is_a? IssuedInvoice and debit?) or (is_a? ReceivedInvoice and transfer?)
      # account is client account, where we should charge
      # or         client account, where we should transfer
      if bank_account
        client.set_if_blank(:bank_account,bank_account)
      else
        # if client iban/bic differs, store them on invoice (#6171)
        self.client_iban = iban unless client.set_if_blank(:iban,iban)
        self.client_bic = bic unless client.set_if_blank(:bic,bic)
      end
      client.save!
      # Use any of our bank_infos to receive the payment, let say the last one,
      # because we dont have this information in the facturae xml
      self.bank_info = company.bank_infos.last
    elsif (is_a? ReceivedInvoice and debit?) or (is_a? IssuedInvoice and transfer?)
      # account is our account, where we should be charged
      # or         our account, where client should transfer
      if bank_account
        self.bank_info = company.bank_infos.find_by_bank_account(bank_account)
      else
        self.bank_info = company.bank_infos.find_by_iban_and_bic(iban,bic)
        unless self.bank_info
          self.bank_info = company.bank_infos.find_by_iban(iban)
        end
      end
      unless self.bank_info
        #TODO: check if user can add more bank infos to his company
        self.bank_info = BankInfo.new(:bank_account => bank_account,
                                      :iban         => iban,
                                      :bic          => bic,
                                      :company_id   => company.id)
      end
    end
  rescue ActiveRecord::RecordInvalid
    raise $!.message # raise RuntimeError
  end

  def next
    project.invoices.where("id > ? and type = ?", self.id, self.type).first
  end

  def previous
    project.invoices.where("id < ? and type = ?", self.id, self.type).last
  end

  def visible_events
    if User.current.admin? or Rails.env == "development"
      events
    else
      events.where("type!='HiddenEvent'")
    end
  end

  def last_audits_without_event
    audts = (self.audits.where('event_id is NULL') +
              self.associated_audits.where('event_id is NULL') +
              self.invoice_lines.collect {|l|
                l.associated_audits.where('event_id is NULL')
              }.flatten).group_by(&:created_at)
    last = []
    audts.keys.sort.reverse.each_with_index do |k,i|
      if i == 0
        last << audts[k]
      elsif (audts.keys.sort.reverse[i-1] - k) <= 2 # allow 2s between creation times
        last << audts[k]
      else
        break
      end
    end
    last.flatten
  end

  def last_success_sending_event
    self.events.reverse.each do |event|
      if event.name == 'success_sending' and
          %w(EventWithFile EventWithUrl EventWithUrlFace).include?(event.type)
        return event
      end
    end
    return nil
  end

  def has_dir3_info?
    oficina_comptable.present? or
      organ_gestor.present? or
      unitat_tramitadora.present? or
      organ_proponent.present? or
      unidad_contratacion.present?
  end

  def has_article_codes?
    return @has_article_codes unless @has_article_codes.nil?
    @has_article_codes = invoice_lines.any? {|l| l.article_code.present? }
  end

  def has_delivery_note_numbers?
    return @has_delivery_note_numbers unless @has_delivery_note_numbers.nil?
    @has_delivery_note_numbers = invoice_lines.any? {|l| l.delivery_note_number.present? }
  end

  def has_line_discounts?
    return @has_line_discounts unless @has_line_discounts.nil?
    @has_line_discounts = invoice_lines.any? {|l| l.discount_percent != 0 }
    @has_line_discounts ||= invoice_lines.any? {|l| l.discount_amount != 0 }
  end

  def has_line_charges?
    return @has_line_charges unless @has_line_charges.nil?
    @has_line_charges = (invoice_lines.to_a.sum(&:charge) > 0)
  end

  def has_line_ponumber?
    return @has_line_ponumber unless @has_line_ponumber.nil?
    @has_line_ponumber = (invoice_lines.collect {|l|
      l.ponumber
    }.uniq.size > 1)
  end

  def amend_reason
    if read_attribute(:amend_reason).blank?
      is_amend? ? '16' : ''
    else
      read_attribute(:amend_reason)
    end
  end

  def self.amend_reason_codes
    %w(01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 80 81 82 83 84 85)
  end

  def client_iban
    self[:client_iban].blank? ? client.iban : self[:client_iban]
  end

  def client_bic
    self[:client_bic].blank? ? client.bic : self[:client_bic]
  end

  protected

  def increment_counter
    Project.increment_counter "#{type.to_s.pluralize.underscore}_count".to_sym, project_id
  end

  def decrement_counter
    Project.decrement_counter "#{type.to_s.pluralize.underscore}_count".to_sym, project_id
  end

  def call_before_save_hook
    Redmine::Hook.call_hook(:model_invoice_before_save, :invoice=>self)
  end

  # non-utf characters can break conversion to PDF and signature
  # done with external java software
  def fields_to_utf8
    TO_UTF_FIELDS.each do |f|
      self.send("#{f}=",Redmine::CodesetUtil.replace_invalid_utf8(self.send(f)))
    end
  end

  def set_lines_order
    i=1
    invoice_lines.each do |line|
      if line.position.is_a?(Integer)
        i=line.position
      else
        line.position = i
      end
      i+=1
    end
  end

  private

  def set_due_date
    # invoices created by rest can have due_date but no terms
    self.terms = "custom" if terms.nil? and due_date.present?
    self.due_date = terms_object.due_date unless terms == "custom"
  end

  def terms_object
    Terms.new(self.terms, self.date)
  end

  def update_imports
    #TODO: new invoice_line can't use invoice.discount_amount without this
    # and while updating, lines have old invoice instance
    self.invoice_lines.each do |il|
      il.invoice = self
    end
    self.import_in_cents = subtotal.cents
    self.total_in_cents = subtotal.cents + tax_amount.cents
  end

  def invoice_must_have_lines
    if invoice_lines.empty? or invoice_lines.all? {|i| i.marked_for_destruction?}
      errors.add(:base, "#{l(:label_invoice)} #{l(:must_have_lines)}")
    end
  end

  def bank_info_belongs_to_self
    if bank_info and bank_info.company != project.company
      errors.add(:base, "Bank info is from other company!")
    end
  end

  def has_all_fields_required_by_external_company
    if client and client.taxcode and project
      taxcode = client.taxcode
      if taxcode[0...2].downcase == project.company.country
        taxcode2 = taxcode[2..-1]
      else
        taxcode2 = "#{project.company.country}#{taxcode}"
      end
      ext_comp = ExternalCompany.where("taxcode in (?, ?)", taxcode, taxcode2).first
    end
    if ext_comp
      ext_comp.required_fields.each do |field|
        if field == "dir3"
          # https://www.ingent.net/issues/6273
          unless new_record?
            errors.add(:organ_gestor, :blank) if organ_gestor.blank?
            errors.add(:unitat_tramitadora, :blank) if unitat_tramitadora.blank?
            errors.add(:oficina_comptable, :blank) if oficina_comptable.blank?
          end
        else
          errors.add(field, :blank) if self.send(field).blank?
        end
      end
    elsif client and client.invoice_format =~ /face/
      errors.add(:organ_gestor, :blank) if organ_gestor.blank?
      errors.add(:unitat_tramitadora, :blank) if unitat_tramitadora.blank?
      errors.add(:oficina_comptable, :blank) if oficina_comptable.blank?
    end
  end

  # we do not want to update timpestamps (updated_at) if it has not been really modified
  def should_record_timestamps?
    (self.changes.keys.map(&:to_sym) - [:state,:has_been_read,:state_updated_at]).present? && super
  end

  # translations for accepts_nested_attributes_for
  def self.human_attribute_name(attribute_key_name, *args)
    super(attribute_key_name.to_s.gsub(/invoice_lines\./,''), *args)
  end

  def attachment_added(obj)
    return if new_record?
    Event.create(
      :name => :invoice_attachment_added,
      :notes => obj.filename,
      :invoice => self,
      :user => User.current
    )
  end

  def attachment_removed(obj)
    Event.create(
      :name => :invoice_attachment_destoy,
      :notes => obj.filename,
      :invoice => self,
      :user => User.current
    )
  end

end
