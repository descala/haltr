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
  has_many :events, :dependent => :destroy, :order => 'created_at'
  #has_many :taxes, :through => :invoice_lines
  belongs_to :project, :counter_cache => true
  belongs_to :client
  belongs_to :amend, :class_name => "Invoice", :foreign_key => 'amend_id'
  belongs_to :bank_info
  has_one :amend_of, :class_name => "Invoice", :foreign_key => 'amend_id'
  belongs_to :quote
  belongs_to :dir3, :primary_key => :organ_gestor_id
  validates_presence_of :client, :date, :currency, :project_id, :unless => Proc.new {|i| i.type == "ReceivedInvoice" }
  validates_inclusion_of :currency, :in  => Money::Currency.table.collect {|k,v| v[:iso_code] }, :unless => Proc.new {|i| i.type == "ReceivedInvoice" }
  validates_numericality_of :charge_amount_in_cents, :allow_nil => true

  before_save :fields_to_utf8
  after_create :increment_counter
  before_destroy :decrement_counter

  accepts_nested_attributes_for :invoice_lines,
    :allow_destroy => true,
    :reject_if => :all_blank
  validates_associated :invoice_lines

  validate :bank_info_belongs_to_self

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

  after_initialize :set_default_values

  def set_default_values
    self.discount_percent ||= 0
    self.currency         ||= self.client.currency rescue nil
    self.currency         ||= self.company.currency rescue nil
    self.currency         ||= Setting.plugin_haltr['default_currency']
  end

  def currency=(v)
    return unless v
    write_attribute(:currency,v.upcase)
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

  def xml_name
    "#{self.pdf_name_without_extension}.xml" rescue "factura-___.xml"
  end

  def pdf_name_without_extension
    "#{l(:label_invoice)}-#{number.gsub('/','')}" rescue "factura-___"
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
    replace_mails = Redmine::Hook.call_hook(:model_invoice_replace_recipient_emails, :invoice=>self)
    mails = replace_mails if replace_mails.any?
    mails.uniq.compact
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

  def payment_method_code(format)
    PAYMENT_CODES[read_attribute(:payment_method)][format]
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
      next if il.marked_for_destruction?
      t += il.total if tax_type.nil? or il.has_tax?(tax_type)
    end
    t - discount(tax_type)
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
    end.compact.join(". ")
    if tax_comments.blank?
      extra_info
    else
      "#{extra_info}. #{tax_comments}".strip
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

  def modified_since_created?
    updated_at > created_at
  end

  def self.create_from_xml(raw_invoice,company,from,md5,transport)
    raw_xml           = raw_invoice.read
    doc               = Nokogiri::XML(raw_xml)
    doc_no_namespaces = doc.dup.remove_namespaces!
    facturae_version  = doc.at_xpath("//FileHeader/SchemaVersion")
    ubl_version       = doc_no_namespaces.at_xpath("//Invoice/UBLVersionID")
    # invoice_format should match format in config/channels.yml
    if facturae_version
      # facturae30 facturae31 facturae32
      invoice_format  = "facturae#{facturae_version.text.gsub(/[^\d]/,'')}"
      logger.info "Creating invoice from xml - format is FacturaE #{facturae_version.text}"
    elsif ubl_version
      #TODO: biiubl20 efffubl oioubl20 pdf peppolubl20 peppolubl21 svefaktura
      invoice_format  = "ubl#{ubl_version.text}"
      logger.info "Creating invoice from xml - format is UBL #{ubl_version.text}"
    else
      logger.info "Creating invoice from xml - unknown format"
      raise "Unknown format"
    end

    xpaths         = Haltr::Utils.xpaths_for(invoice_format)
    seller_taxcode = Haltr::Utils.get_xpath(doc,xpaths[:seller_taxcode])
    buyer_taxcode  = Haltr::Utils.get_xpath(doc,xpaths[:buyer_taxcode])
    currency       = Haltr::Utils.get_xpath(doc,xpaths[:currency])
    invoice, client, client_role = nil

    # check if it is a received_invoice or an issued_invoice.
    if company.taxcode == buyer_taxcode
      invoice = ReceivedInvoice.new
      client = seller_taxcode.blank? ? nil : company.project.clients.find_by_taxcode(seller_taxcode)
      client_role= "seller"
    elsif company.taxcode == seller_taxcode
      invoice = IssuedInvoice.new
      client = buyer_taxcode.blank? ? nil : company.project.clients.find_by_taxcode(buyer_taxcode)
      client_role = "buyer"
    else
      raise I18n.t :taxcodes_does_not_belong_to_self,
        :tcs => "#{buyer_taxcode} - #{seller_taxcode}",
        :tc  => company.taxcode
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
      # set new client's channel to match invoice format, and sent by mail
      case invoice_format
      when /^facturae3/
        client_invoice_format = invoice_format.gsub(/facturae3(\d)/,"facturae_3\\1")
      else
        client_invoice_format = "#TODO"
      end

      client = Client.new(:taxcode        => client_taxcode,
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
                          :invoice_format => client_invoice_format)
      client.save!(:validate=>false)
      logger.info "created new client \"#{client_name}\" with cif #{client_taxcode} for company #{company.name}"
    end

    # invoice data
    invoice_number   = Haltr::Utils.get_xpath(doc,xpaths[:invoice_number])
    invoice_date     = Haltr::Utils.get_xpath(doc,xpaths[:invoice_date])
    invoice_total    = Haltr::Utils.get_xpath(doc,xpaths[:invoice_total])
    invoice_import   = Haltr::Utils.get_xpath(doc,xpaths[:invoice_import])
    invoice_due_date = Haltr::Utils.get_xpath(doc,xpaths[:invoice_due_date])
    discount_percent = Haltr::Utils.get_xpath(doc,xpaths[:discount_percent])
    discount_text    = Haltr::Utils.get_xpath(doc,xpaths[:discount_text])
    extra_info       = Haltr::Utils.get_xpath(doc,xpaths[:extra_info])
    charge           = Haltr::Utils.get_xpath(doc,xpaths[:charge])
    charge_reason    = Haltr::Utils.get_xpath(doc,xpaths[:charge_reason])
    accounting_cost  = Haltr::Utils.get_xpath(doc,xpaths[:accounting_cost])

    invoice.assign_attributes(
      :number           => invoice_number,
      :client           => client,
      :date             => invoice_date,
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
      :original         => raw_xml,
      :discount_percent => discount_percent.to_f,
      :discount_text    => discount_text,
      :extra_info       => extra_info,
      :charge_amount    => charge,
      :charge_reason    => charge_reason,
      :accounting_cost  => accounting_cost,
    )

    if raw_invoice.respond_to? :filename             # Mail::Part
      invoice.file_name = raw_invoice.filename
    elsif raw_invoice.respond_to? :original_filename # UploadedFile
      invoice.file_name = raw_invoice.original_filename
    elsif raw_invoice.respond_to? :path              # File (tests)
      invoice.file_name = File.basename(raw_invoice.path)
    else
      invoice.file_name = "can't get filename from #{raw_invoice.class}"
    end

    if Haltr::Utils.get_xpath(doc,xpaths[:to_be_debited])
      invoice.payment_method=PAYMENT_DEBIT
    elsif Haltr::Utils.get_xpath(doc,xpaths[:to_be_credited])
      invoice.payment_method=PAYMENT_TRANSFER
    else
      invoice.payment_method=PAYMENT_CASH
    end

    # bank info
    if invoice.debit?
      invoice.parse_xml_bank_info(doc.xpath(xpaths[:to_be_debited]).to_s)
    elsif invoice.transfer?
      invoice.parse_xml_bank_info(doc.xpath(xpaths[:to_be_credited]).to_s)
    end

    # invoice lines
    doc.xpath(xpaths[:invoice_lines]).each do |line|
      il = InvoiceLine.new(
             :quantity     => Haltr::Utils.get_xpath(line,xpaths[:line_quantity]),
             :description  => Haltr::Utils.get_xpath(line,xpaths[:line_description]),
             :price        => Haltr::Utils.get_xpath(line,xpaths[:line_price]),
             :unit         => Haltr::Utils.get_xpath(line,xpaths[:line_unit]),
             :article_code => Haltr::Utils.get_xpath(line,xpaths[:line_code]),
             :notes        => Haltr::Utils.get_xpath(line,xpaths[:line_notes])
           )
      # invoice taxes. Known taxes are described at config/taxes.yml
      line.xpath(*xpaths[:line_taxes]).each do |line_tax|
        tax = Haltr::TaxHelper.new_tax(
          :format  => invoice_format,
          :id      => Haltr::Utils.get_xpath(line_tax,xpaths[:tax_id]),
          :percent => Haltr::Utils.get_xpath(line_tax,xpaths[:tax_percent])
        )
        il.taxes << tax
      end
      invoice.invoice_lines << il
    end

    Redmine::Hook.call_hook(:model_invoice_import_before_save, :invoice=>invoice)

    invoice.save!
    logger.info "created new invoice with id #{invoice.id} for company #{company.name}"
    return invoice
  end

  def parse_xml_bank_info(xml)
    doc          = Nokogiri::XML(xml)
    xpaths       = Haltr::Utils.xpaths_for(invoice_format)
    bank_account = Haltr::Utils.get_xpath(doc,xpaths[:bank_account])
    iban         = Haltr::Utils.get_xpath(doc,xpaths[:iban])
    bic          = Haltr::Utils.get_xpath(doc,xpaths[:bic])
    return unless bank_account or ( iban and bic )
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

  def can_be_exported?
    false
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
    #TODO: new invoice_line can't use invoice.discount without this
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
    if bank_info and client and bank_info.company != client.project.company
      errors.add(:base, "Bank info is from other company!")
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
