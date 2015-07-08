class Invoice < ActiveRecord::Base

  unloadable

  include HaltrHelper
  include Haltr::FloatParser
  float_parse :discount_percent, :fa_import

  audited except: [:import_in_cents, :total_in_cents,
                   :state, :has_been_read, :id, :original]
  has_associated_audits
  # do not remove, with audit we need to make the other attributes accessible
  attr_protected :created_at, :updated_at
  attr_accessor :discount_helper

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

  has_many :invoice_lines, :dependent => :destroy
  has_many :events, :order => 'created_at'
  #has_many :taxes, :through => :invoice_lines
  belongs_to :project, :counter_cache => true
  belongs_to :client
  belongs_to :amend, :class_name => "Invoice", :foreign_key => 'amend_id'
  belongs_to :bank_info
  has_one :amend_of, :class_name => "Invoice", :foreign_key => 'amend_id'
  belongs_to :quote
  has_many :comments, :as => :commented, :dependent => :delete_all, :order => "created_on"

  validates_presence_of :client, :date, :currency, :project_id, :unless => Proc.new {|i| i.type == "ReceivedInvoice" }
  validates_inclusion_of :currency, :in  => Money::Currency.table.collect {|k,v| v[:iso_code] }, :unless => Proc.new {|i| i.type == "ReceivedInvoice" }
  validates_numericality_of :charge_amount_in_cents, :allow_nil => true
  validates_numericality_of :payments_on_account_in_cents, :allow_nil => true

  before_save :fields_to_utf8
  after_create :increment_counter
  before_destroy :decrement_counter

  accepts_nested_attributes_for :invoice_lines,
    :allow_destroy => true,
    :reject_if => :all_blank
  validates_associated :invoice_lines

  validate :bank_info_belongs_to_self
  validate :has_all_fields_required_by_external_company

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

  after_initialize :set_default_values

  acts_as_attachable :view_permission => :use_invoice_attachments, :delete_permission => :use_invoice_attachments

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
    (lines_with_tax(tax_type).collect { |line|
      line.gross_amount.to_money(currency)
    }.sum).to_money(currency)
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
    client.recipient_emails
  end

  def terms_description
    terms_object.description
  end

  # for transfer payment method it returns an entry for each bank_account on company:
  # ["transfer to <bank_info.name>", "<PAYMENT_TRANSFER>_<bank_info.id>"]
  # or one generic entry if there are no bank_infos on company:
  # ["transfer", PAYMENT_TRANSFER]
  def self.payment_methods(company)
    pm = [['---',''],[l("cash"), PAYMENT_CASH]]
    if company.bank_infos.any?
      tr = []
      db = []
      company.bank_infos.each do |bank_info|
        tr << [l("debit_through",:bank_account=>bank_info.name), "#{PAYMENT_DEBIT}_#{bank_info.id}"]
        db << [l("transfer_to",:bank_account=>bank_info.name),"#{PAYMENT_TRANSFER}_#{bank_info.id}"]
      end
      pm += tr
      pm += db
    else
      pm << [l("transfer"),PAYMENT_TRANSFER]
    end
    pm << [l("other"),PAYMENT_SPECIAL]
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
    if [PAYMENT_TRANSFER, PAYMENT_DEBIT].include?(read_attribute(:payment_method)) and bank_info
      "#{read_attribute(:payment_method)}_#{bank_info.id}"
    else
      read_attribute(:payment_method)
    end
  end

  def cash?
    read_attribute(:payment_method) == PAYMENT_CASH
  end

  def debit?
    read_attribute(:payment_method) == PAYMENT_DEBIT
  end

  def transfer?
    read_attribute(:payment_method) == PAYMENT_TRANSFER
  end

  def special?
    read_attribute(:payment_method) == PAYMENT_SPECIAL
  end

  def payment_method_code(format, attr=:payment_method)
    if PAYMENT_CODES[self[attr].to_i]
      PAYMENT_CODES[self[attr].to_i][format]
    end
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

  # Base imponible a precio de mercado
  # Total Importe Bruto + Recargos - Descuentos Globales
  def taxable_base(tax_type=nil)
    (lines_with_tax(tax_type).collect {|line|
      line.gross_amount.to_money(currency)
    }.sum).to_money(currency) - discount_amount(tax_type)
  end

  def discount_amount(tax_type=nil)
    self.discount_percent = 0 if self.discount_percent.nil?
    gross_subtotal * (discount_percent / 100.0)
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
    if value =~ /^[0-9,.']*$/
      value = Money.parse(value)
      write_attribute :charge_amount_in_cents, value.cents
    else
      # this + validates_numericality_of will raise an error if not a number
      write_attribute :charge_amount_in_cents, value
    end
  end

  def payments_on_account=(value)
    if value =~ /^[0-9,.']*$/
      value = Money.parse(value)
      write_attribute :payments_on_account_in_cents, value.cents
    else
      # this + validates_numericality_of will raise an error if not a number
      write_attribute :payments_on_account_in_cents, value
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
      tax.comment unless tax.comment.blank?
    end.compact.uniq.join(". ")
    ([extra_info,tax_comments]-['']).compact.join('. ')
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
    updated_at > created_at
  end

  # has factoring assignment data?
  def has_factoring_data?
    %w(fa_person_type fa_residence_type fa_taxcode).reject { |attr|
      self.send(attr).blank? or self.send(attr) == 0
    }.size == 3
  end

  def self.create_from_xml(raw_invoice,user_or_company,md5,transport,from=nil,issued=nil,keep_original=true,validate=true)

    if raw_invoice.is_a? String
      raw_xml = raw_invoice
    else
      raw_xml = raw_invoice.read
    end
    doc               = Nokogiri::XML(raw_xml)
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
    buyer_taxcode  = Haltr::Utils.get_xpath(doc,xpaths[:buyer_taxcode])
    currency       = Haltr::Utils.get_xpath(doc,xpaths[:currency])
    # invoice data
    invoice_number   = Haltr::Utils.get_xpath(doc,xpaths[:invoice_number])
    invoice_series   = Haltr::Utils.get_xpath(doc,xpaths[:invoice_series])
    invoice_date     = Haltr::Utils.get_xpath(doc,xpaths[:invoice_date])
    i_period_start   = Haltr::Utils.get_xpath(doc,xpaths[:invoicing_period_start])
    i_period_end     = Haltr::Utils.get_xpath(doc,xpaths[:invoicing_period_end])
    invoice_total    = Haltr::Utils.get_xpath(doc,xpaths[:invoice_total])
    invoice_import   = Haltr::Utils.get_xpath(doc,xpaths[:invoice_import])
    invoice_due_date = Haltr::Utils.get_xpath(doc,xpaths[:invoice_due_date])
    discount_percent = Haltr::Utils.get_xpath(doc,xpaths[:discount_percent])
    discount_text    = Haltr::Utils.get_xpath(doc,xpaths[:discount_text])
    extra_info       = Haltr::Utils.get_xpath(doc,xpaths[:extra_info])
    charge           = Haltr::Utils.get_xpath(doc,xpaths[:charge])
    charge_reason    = Haltr::Utils.get_xpath(doc,xpaths[:charge_reason])
    accounting_cost  = Haltr::Utils.get_xpath(doc,xpaths[:accounting_cost])
    payments_on_account = Haltr::Utils.get_xpath(doc,xpaths[:payments_on_account]) || 0
    amend_of         = Haltr::Utils.get_xpath(doc,xpaths[:amend_of])
    party_id         = Haltr::Utils.get_xpath(doc,xpaths[:party_id])

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
    fa_payment_method = Haltr::Utils.payment_method_from_facturae(fa_payment_method)

    invoice, client, client_role, company, user = nil

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

    # check if it is a received_invoice or an issued_invoice.
    if company.taxcode.include?(buyer_taxcode) or buyer_taxcode.include?(company.taxcode)
      invoice = ReceivedInvoice.new
      client   = company.project.clients.where('taxcode like ?', "%#{seller_taxcode}").first
      client ||= company.project.clients.where('? like concat("%", taxcode)', seller_taxcode).first
      client_role= "seller"
    elsif company.taxcode.include?(seller_taxcode) or seller_taxcode.include?(company.taxcode)
      invoice = IssuedInvoice.new
      client   = company.project.clients.where('taxcode like ?', "%#{buyer_taxcode}").first
      client ||= company.project.clients.where('? like concat("%", taxcode)', buyer_taxcode).first
      client_role = "buyer"
    else
      raise I18n.t :taxcodes_does_not_belong_to_self,
        :tcs => "#{buyer_taxcode} - #{seller_taxcode}",
        :tc  => company.taxcode
    end

    # amend invoices
    if amend_of
      raise "Cannot amend received invoices" if invoice.is_a? ReceivedInvoice
      amended = company.project.issued_invoices.find_by_number(amend_of)
      if amended
        invoice.amend_of = amended
      else
        # importing amend invoice for an unexisting invoice, assign self id as
        # amended_invoice as a dirty hack
        invoice.amend_of = invoice
      end
    end


    # if passed issued param, check if it should be an IssuedInvoice or a ReceivedInvoice
    unless issued.nil?
      if !issued and invoice.is_a? IssuedInvoice
        raise l(:import_issued_from_received)
      elsif issued and invoice.is_a? ReceivedInvoice
        raise l(:import_received_from_issued)
      end
    end

    # create client if not exists
    unless client
      client_taxcode     = client_role == "seller" ? seller_taxcode : buyer_taxcode
      client_name        = Haltr::Utils.get_xpath(doc,xpaths["#{client_role}_name"]) ||
                           Haltr::Utils.get_xpath(doc,xpaths["#{client_role}_name2"])
      client_address     = Haltr::Utils.get_xpath(doc,xpaths["#{client_role}_address"])
      client_province    = Haltr::Utils.get_xpath(doc,xpaths["#{client_role}_province"])
      if invoice_format =~ /^facturae/
        country_alpha3 = Haltr::Utils.get_xpath(doc,xpaths["#{client_role}_countrycode"])
        client_countrycode = SunDawg::CountryIsoTranslater.translate_standard(country_alpha3,"alpha3","alpha2").downcase
      else
        client_countrycode = Haltr::Utils.get_xpath(doc,xpaths["#{client_role}_countrycode"])
      end
      client_website     = Haltr::Utils.get_xpath(doc,xpaths["#{client_role}_website"])
      client_email       = Haltr::Utils.get_xpath(doc,xpaths["#{client_role}_email"])
      client_cp_city     = Haltr::Utils.get_xpath(doc,xpaths["#{client_role}_cp_city"]) ||
                           Haltr::Utils.get_xpath(doc,xpaths["#{client_role}_cp_city2"])
      client_postalcode  = client_cp_city.split(" ").first rescue ""
      client_city        = client_cp_city.gsub(/^#{client_postalcode} /,'') rescue ""
      if client_postalcode.blank?
        client_postalcode  = Haltr::Utils.get_xpath(doc,xpaths["#{client_role}_cp"])
      end

      client_language = User.current.language
      client_language = 'es' if client_language.blank?

      client = Client.new(
        :taxcode        => client_taxcode,
        :name           => client_name,
        :address        => client_address,
        :province       => client_province,
        :country        => client_countrycode,
        :website        => client_website,
        :email          => client_email,
        :postalcode     => client_postalcode,
        :city           => client_city,
        :currency       => currency,
        :project        => company.project,
        :invoice_format => 'paper',
        :language       => client_language
      )

      client.save!(:validate=>false)
      logger.info "created new client \"#{client_name}\" with cif #{client_taxcode} for company #{company.name}. time=#{Time.now}"
    end

    doc.xpath(xpaths[:dir3s]).each do |line|
      case Haltr::Utils.get_xpath(line, xpaths[:dir3_role])
      when '01'
        invoice.oficina_comptable  = Haltr::Utils.get_xpath(line, xpaths[:dir3_code])
        invoice.oficina_comptable_name = Haltr::Utils.get_xpath(line, xpaths[:dir3_name])
      when '02'
        invoice.organ_gestor       = Haltr::Utils.get_xpath(line, xpaths[:dir3_code])
      when '03'
        invoice.unitat_tramitadora = Haltr::Utils.get_xpath(line, xpaths[:dir3_code])
      when '04'
        invoice.organ_proponent    = Haltr::Utils.get_xpath(line, xpaths[:dir3_code])
      else
        # unknown role
      end
    end

    invoice.assign_attributes(
      :number           => invoice_number,
      :series_code      => invoice_series,
      :client           => client,
      :date             => invoice_date,
      :invoicing_period_start => i_period_start,
      :invoicing_period_end   => i_period_end,
      :total            => invoice_total.to_money(currency),
      :currency         => currency,
      :import           => invoice_import.to_money(currency),
      :due_date         => invoice_due_date,
      :project          => company.project,
      :terms            => "custom",
      :invoice_format   => invoice_format, # facturae3.2, ubl21...
      :transport        => transport,      # email, uploaded
      :from             => from,           # u@mail.com, User Name...
      :md5              => md5,
      :original         => keep_original ? raw_xml : nil,
      :discount_percent => discount_percent,
      :discount_text    => discount_text,
      :extra_info       => extra_info,
      :charge_amount    => charge,
      :charge_reason    => charge_reason,
      :accounting_cost  => accounting_cost,
      :payments_on_account => payments_on_account.to_money(currency),
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
    )

    if raw_invoice.respond_to? :filename             # Mail::Part
      invoice.file_name = raw_invoice.filename
    elsif raw_invoice.respond_to? :original_filename # UploadedFile
      invoice.file_name = raw_invoice.original_filename
    elsif raw_invoice.respond_to? :path              # File (tests)
      invoice.file_name = File.basename(raw_invoice.path)
    else
      invoice.file_name = "invoice.xml"
    end

    if invoice_format =~ /facturae/
      xml_payment_method = Haltr::Utils.get_xpath(doc,xpaths[:payment_method])
      invoice.payment_method = Haltr::Utils.payment_method_from_facturae(xml_payment_method)
    else
      #TODO ubl
    end

    # bank info
    if invoice.debit?
      invoice.parse_xml_bank_info(doc.xpath(xpaths[:to_be_debited]).to_s)
    elsif invoice.transfer?
      invoice.parse_xml_bank_info(doc.xpath(xpaths[:to_be_credited]).to_s)
    end
    invoice.payment_method_text = Haltr::Utils.get_xpath(doc,xpaths[:payment_method_text])

    line_file_reference = nil
    line_ponumber = nil
    line_r_contract_reference = nil

    # invoice lines
    doc.xpath(xpaths[:invoice_lines]).each do |line|

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
             :quantity     => Haltr::Utils.get_xpath(line,xpaths[:line_quantity]),
             :description  => Haltr::Utils.get_xpath(line,xpaths[:line_description]),
             :price        => Haltr::Utils.get_xpath(line,xpaths[:line_price]),
             :unit         => unit,
             :article_code => Haltr::Utils.get_xpath(line,xpaths[:line_code]),
             :notes        => Haltr::Utils.get_xpath(line,xpaths[:line_notes]),
             :issuer_transaction_reference => Haltr::Utils.get_xpath(line,xpaths[:i_transaction_ref]),
             :sequence_number              => Haltr::Utils.get_xpath(line,xpaths[:sequence_number]),
             :delivery_note_number         => line_delivery_note_number,
           )
      # invoice taxes. Known taxes are described at config/taxes.yml
      line.xpath(*xpaths[:line_taxes]).each do |line_tax|
        tax = Haltr::TaxHelper.new_tax(
          :format  => invoice_format,
          :id      => Haltr::Utils.get_xpath(line_tax,xpaths[:tax_id]),
          :percent => Haltr::Utils.get_xpath(line_tax,xpaths[:tax_percent]),
          :event_code => Haltr::Utils.get_xpath(line,xpaths[:tax_event_code]),
          :event_reason => Haltr::Utils.get_xpath(line,xpaths[:tax_event_reason])
        )
        il.taxes << tax
      end
      # line discounts
      line_discounts = line.xpath(xpaths[:line_discounts])
      if line_discounts.size > 1
        raise "too many discounts per line! (#{line_discounts.size})"
      elsif line_discounts.size == 1
        il.discount_percent = Haltr::Utils.get_xpath(line_discounts.first,xpaths[:line_discount_percent])
        il.discount_text = Haltr::Utils.get_xpath(line_discounts.first,xpaths[:line_discount_text])
      end
      # line_charges
      line_charges = line.xpath(xpaths[:line_charges])
      if line_charges.size > 1
        raise "too many charges per line! (#{line_charges.size})"
      elsif line_charges.size == 1
        il.charge = Haltr::Utils.get_xpath(line_charges.first,xpaths[:line_charge])
        il.charge_reason = Haltr::Utils.get_xpath(line_charges.first,xpaths[:line_charge_reason])
      end
      line_file_reference ||= Haltr::Utils.get_xpath(line,xpaths[:file_reference])
      line_ponumber       ||= Haltr::Utils.get_xpath(line,xpaths[:ponumber])
      line_r_contract_reference ||= Haltr::Utils.get_xpath(line,xpaths[:r_contract_reference])
      invoice.invoice_lines << il
    end

    # Assume just one file_reference, ponumber and
    # receiver_contract_reference per Invoice
    invoice.file_reference = line_file_reference
    invoice.ponumber = line_ponumber
    invoice.receiver_contract_reference = line_r_contract_reference

    # attachments
    to_attach = []
    doc.xpath(xpaths[:attachments]).each_with_index do |attach, index|
      data             = Haltr::Utils.get_xpath(attach, xpaths[:attach_data])
      data_compression = Haltr::Utils.get_xpath(attach, xpaths[:attach_compression_algorithm])
      data_format      = Haltr::Utils.get_xpath(attach, xpaths[:attach_format])
      data_encoding    = Haltr::Utils.get_xpath(attach, xpaths[:attach_encoding])
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
      a.filename = "attachment#{index+1}.#{ext}"
      to_attach << a
    end
    invoice.attachments = to_attach

    Redmine::Hook.call_hook(:model_invoice_import_before_save, :invoice=>invoice)

    if keep_original
      begin
        if validate
          invoice.save!
        else
          invoice.save(validate: false)
        end
      rescue ActiveRecord::RecordInvalid
        raise invoice.errors.full_messages.join(". ")
      end
    else
      invoice.save(:validate=>false)
    end
    logger.info "created new invoice with id #{invoice.id} for company #{company.name}. time=#{Time.now}"
    return invoice
  rescue
    if company and company.project
      ImportError.create(
        filename:      (invoice.file_name rescue ""),
        import_errors: $!.message,
        original:      raw_xml,
        project:       company.project,
      )
    end
    raise $!.message
  end

  def send_original?
    Redmine::Hook.call_hook(:model_invoice_send_original, :invoice=>self) != [false] and
      original and !modified_since_created? and invoice_format != 'pdf'
  end

  def parse_xml_bank_info(xml)
    doc          = Nokogiri::XML(xml)
    xpaths       = Haltr::Utils.xpaths_for(invoice_format)
    bank_account = Haltr::Utils.get_xpath(doc,xpaths[:bank_account])
    iban         = Haltr::Utils.get_xpath(doc,xpaths[:iban])
    bic          = Haltr::Utils.get_xpath(doc,xpaths[:bic])
    return unless bank_account or iban
    if (is_a? IssuedInvoice and debit?) or (is_a? ReceivedInvoice and transfer?)
      # account is client account, where we should charge
      # or         client account, where we should transfer
      if bank_account
        client.set_if_blank(:bank_account,bank_account)
      else
        client.set_if_blank(:iban,iban)
        client.set_if_blank(:bic,bic)
      end
      client.save!
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
  end

  def next
    project.invoices.first(:conditions=>["id > ? and type = ?", self.id, self.type])
  end

  def previous
    project.invoices.last(:conditions=>["id < ? and type = ?", self.id, self.type])
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
    @has_line_discounts = (invoice_lines.sum(&:discount_percent) > 0)
  end

  def has_line_charges?
    return @has_line_charges unless @has_line_charges.nil?
    @has_line_charges = (invoice_lines.sum(&:charge) > 0)
  end

  protected

  def increment_counter
    Project.increment_counter "invoices_count", project_id
    Project.increment_counter "#{type.to_s.pluralize.underscore}_count", project_id
  end

  def decrement_counter
    Project.decrement_counter "invoices_count", project_id
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
    #TODO: new invoice_line can't use invoice.discount_amount without this
    # and while updating, lines have old invoice instance
    self.invoice_lines.each do |il|
      il.invoice = self
    end
    self.import_in_cents = subtotal.cents
    self.total_in_cents = subtotal.cents + tax_amount.cents

    unless discount_percent and discount_percent > 0
      if discount_helper.present?
        self.discount_percent = (discount_helper.to_f * 100 / gross_subtotal.dollars)
      end
    end
  end

  def invoice_must_have_lines
    if invoice_lines.empty? or invoice_lines.all? {|i| i.marked_for_destruction?}
      errors.add(:base, "#{l(:label_invoice)} #{l(:must_have_lines)}")
    end
  end

  def bank_info_belongs_to_self
    if bank_info and client and bank_info.company != client.project.company
      errors.add(:base, "Bank info is from other company!")
    end
  end

  def has_all_fields_required_by_external_company
    if client and client.taxcode
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
          errors.add(:organ_gestor, :blank) if organ_gestor.blank?
          errors.add(:unitat_tramitadora, :blank) if unitat_tramitadora.blank?
          errors.add(:oficina_comptable, :blank) if oficina_comptable.blank?
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
    (self.changes.keys.map(&:to_sym) - [:state,:has_been_read]).present? && super
  end

  # translations for accepts_nested_attributes_for
  def self.human_attribute_name(attribute_key_name, *args)
    super(attribute_key_name.to_s.gsub(/invoice_lines\./,''), *args)
  end

end
