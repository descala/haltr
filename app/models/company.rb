class Company < ActiveRecord::Base

  unloadable

  ROUNDING_METHODS = %w( half_up bankers truncate )

  belongs_to :project

  # these are the linked clients: where this company apears in other
  # companies' client list
  has_many :clients, :as => :company, :dependent => :nullify
  has_many :taxes, :class_name => "Tax", :dependent => :destroy, :order => "name,percent DESC"
  has_many :bank_infos, :dependent => :destroy, :order => "name,bank_account,iban,bic DESC"
  validates_presence_of :name, :project_id, :email, :postalcode, :country
  validates_uniqueness_of :taxcode, :allow_blank => true
  validates_inclusion_of :currency, :in  => Money::Currency.table.collect {|k,v| v[:iso_code] }
  validates_inclusion_of :rounding_method, :in => ROUNDING_METHODS
  validates_format_of :email,
    :with => /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+(,[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+)*\z/,
    :allow_nil => true
  validate :only_one_default_tax_per_name
  acts_as_attachable :view_permission => :general_use,
                     :delete_permission => :general_use
  after_save :update_linked_clients
  iso_country :country
  include CountryUtils
  include Haltr::TaxcodeValidator

  accepts_nested_attributes_for :taxes,
    :allow_destroy => true,
    :reject_if => :all_blank
  validates_associated :taxes

  accepts_nested_attributes_for :bank_infos,
    :allow_destroy => true,
    :reject_if => :all_blank
  validates_associated :bank_infos

  validate :uniqueness_of_taxes

  after_initialize :set_default_values
  serialize :invoice_mail_customization
  serialize :quote_mail_customization

  def set_default_values
    #TODO: Add default country taxes
    self.currency ||= Setting.plugin_haltr['default_currency']
    self.country  ||= Setting.plugin_haltr['default_country']
    self.attachments ||= []
    self.invoice_mail_customization ||= {}
    self.quote_mail_customization ||= {}
  end

  def <=>(oth)
    self.name <=> oth.name
  end

  def first_name
    name.split(" ").first
  end

  # https://www.ingent.net/issues/5425
  def last_name
    ln = name.split(" ")
    ln.shift
    ln = ln.join(" ")
    ln = '.' if ln.blank?
    ln
  end

  def currency=(v)
    return unless v
    write_attribute(:currency,v.upcase)
  end

  def public?
    self.public == "public"
  end

  def semipublic?
    self.public == "semipublic"
  end

  def private?
    self.public == "private"
  end

  def companies_with_link_requests
    self.clients.collect do |client|
      next unless client.project and client.project.company
      client.project.company if client.allowed?.nil?
    end.compact
  end

  def companies_with_denied_link
    self.clients.collect do |client|
      next unless client.project and client.project.company
      client.project.company if client.allowed? == false
    end.compact
  end

  def only_one_default_tax_per_name
    deftaxes = {}
    taxes.each do |tax|
      next if tax.marked_for_destruction?
      errors.add(:base, l(:only_one_default_allowed_for, :tax_name=>tax.name)) if deftaxes[tax.name] and tax.default
      deftaxes[tax.name] = tax.default
    end
  end

  def tax_names
    taxes.collect {|tax| tax.name }.uniq
  end

  def bank_accounts
    self.bank_infos.collect {|bi|
      bi.bank_account
    }.compact.uniq
  end

  def ibans
    self.bank_infos.collect {|bi|
      bi.iban
    }.compact.uniq
  end

  # workaround rails bug that allows to save invalid taxes on company
  # see https://github.com/rails/rails/issues/4568
  def uniqueness_of_taxes
    my_taxes = {}
    taxes.each do |tax|
      next if tax.marked_for_destruction?
      nc = "#{tax[:name]}#{tax[:category]}"
      my_taxes[tax.percent] = [] unless my_taxes.has_key?(tax.percent)
      errors.add(:taxes, :invalid) if my_taxes[tax.percent].include?(nc)
      my_taxes[tax.percent] << nc
    end
  end

  # http://inza.wordpress.com/2013/10/25/como-preparar-los-mandatos-sepa-identificador-del-acreedor/
  def sepa_creditor_identifier
    # remove country code from taxcode
    creditor_business_code = taxcode.gsub(/^#{country}/i,'') rescue ''
    # if there is no taxcode try with company_identifier
    creditor_business_code = company_identifier if creditor_business_code==''
    num = "#{creditor_business_code}#{country_alpha2}00".downcase.each_byte.collect do |c|
      if c <= 57
        c.chr
      else
        c - 87
      end
    end.join.to_i
    # MOD97-10 from ISO 7064
    control = (98 - ( num % 97 )).to_s.rjust(2,'0')
    # This "000" is the "sufix" in Spanish AEB
    "#{country_alpha2}#{control}000#{creditor_business_code}"
  end

  def default_tax_code_for(name)
    taxes.collect {|t| t if t.name == name and t.default }.compact.first.code
  rescue
    ""
  end

  ################## methods for mail customization ##################
  def invoice_mail_subject(lang,invoice=nil)
    subj = invoice_mail_customization["subject"][lang] rescue nil
    if subj.blank?
      subj = I18n.t(:invoice_mail_subject,:locale=>lang)
      unless Redmine::Hook.call_hook(:replace_invoice_mail_subject).join.blank?
        subj = Redmine::Hook.call_hook(:replace_invoice_mail_subject,:lang=>lang).join
      end
    end
    if invoice
      #TODO: define allowed methods here for safety
      subj = subj.gsub(/@invoice\.(\w+)/) {|s|
        invoice.send($1) rescue s
      }.gsub(/@client\.(\w+)/) {|s|
        invoice.client.send($1) rescue s
      }
    end
    subj
  end

  def invoice_mail_subject=(lang,value)
    self.invoice_mail_customization = {} unless invoice_mail_customization.is_a? Hash
    self.invoice_mail_customization["subject"] = {} unless invoice_mail_customization["subject"]
    self.invoice_mail_customization["subject"][lang] = value
  end

  def invoice_mail_body(lang,invoice=nil)
    body = invoice_mail_customization["body"][lang] rescue nil
    if body.blank?
      body = I18n.t(:invoice_mail_body,:locale=>lang)
      unless Redmine::Hook.call_hook(:replace_invoice_mail_body).join.blank?
        body = Redmine::Hook.call_hook(:replace_invoice_mail_body,:lang=>lang).join
      end
    end
    if invoice
      #TODO: define allowed methods here for safety
      body = body.gsub(/@invoice\.(\w+)/) {|s|
        invoice.send($1) rescue s
      }.gsub(/@client\.(\w+)/) {|s|
        invoice.client.send($1) rescue s
      }
    end
    body
  end

  def invoice_mail_body=(lang,value)
    self.invoice_mail_customization = {} unless invoice_mail_customization.is_a? Hash
    self.invoice_mail_customization["body"] = {} unless invoice_mail_customization["body"]
    self.invoice_mail_customization["body"][lang] = value
  end

  def quote_mail_subject(lang,quote=nil)
    subj = quote_mail_customization["subject"][lang] rescue nil
    if subj.blank?
      subj = I18n.t(:quote_mail_subject,:locale=>lang)
      unless Redmine::Hook.call_hook(:replace_quote_mail_subject).join.blank?
        subj = Redmine::Hook.call_hook(:replace_quote_mail_subject,:lang=>lang).join
      end
    end
    if quote
      #TODO: define allowed methods here for safety
      subj = subj.gsub(/@quote\.(\w+)/) {|s|
        quote.send($1) rescue s
      }.gsub(/@client\.(\w+)/) {|s|
        quote.client.send($1) rescue s
      }
    end
    subj
  end

  def quote_mail_subject=(lang,value)
    self.quote_mail_customization = {} unless quote_mail_customization.is_a? Hash
    self.quote_mail_customization["subject"] = {} unless quote_mail_customization["subject"]
    self.quote_mail_customization["subject"][lang] = value
  end

  def quote_mail_body(lang,quote=nil)
    body = quote_mail_customization["body"][lang] rescue nil
    if body.blank?
      body = I18n.t(:quote_mail_body,:locale=>lang)
      unless Redmine::Hook.call_hook(:replace_quote_mail_body).join.blank?
        body = Redmine::Hook.call_hook(:replace_quote_mail_body,:lang=>lang).join
      end
    end
    if quote
      #TODO: define allowed methods here for safety
      body = body.gsub(/@quote\.(\w+)/) {|s|
        quote.send($1) rescue s
      }.gsub(/@client\.(\w+)/) {|s|
        quote.client.send($1) rescue s
      }
    end
    body
  end

  def quote_mail_body=(lang,value)
    self.quote_mail_customization = {} unless quote_mail_customization.is_a? Hash
    self.quote_mail_customization["body"] = {} unless quote_mail_customization["body"]
    self.quote_mail_customization["body"][lang] = value
  end
  ####################################################################

  def respond_to?(method, include_private = false)
    super || method =~ /^(invoice|quote)_mail_(subject|body)_[a-z][a-z][\-A-Z]{0,3}=?$/
  end

  def language
    self.project.users.collect {|u| u unless u.admin?}.compact.first.language
  rescue
    I18n.default_locale.to_s
  end

  # for select on my_company view
  def self.rounding_methods
    ROUNDING_METHODS.collect {|m|
      [ I18n.t("#{m}_rounding"), m ]
    }
  end

  private

  def update_linked_clients
    self.clients.each do |client|
      if self.private?
        client.company=nil
        client.allowed=nil
      end
      client.save
    end
  end

  # translations for accepts_nested_attributes_for
  def self.human_attribute_name(attribute_key_name, *args)
    super(attribute_key_name.to_s.gsub(/bank_infos\./,''), *args)
  end

  def method_missing(m, *args)
    if /^(?<method>invoice_mail_subject|invoice_mail_body|quote_mail_subject|quote_mail_body)_(?<lang>[a-z][a-z][\-A-Z]{0,3})$/ =~ m.to_s and (0..1).include? args.size
      # mail_<subject|body>_<lang>([invoice])
      self.public_send(method,lang,args[0])
    elsif /^(?<method>invoice_mail_subject|invoice_mail_body|quote_mail_subject|quote_mail_body)_(?<lang>[a-z][a-z][\-A-Z]{0,3})=$/ =~ m.to_s and args.size == 1
      # mail_<subject|body>_<lang>=(<value>)
      self.public_send("#{method}=",lang,args[0])
    else
      super
    end
  end

end
