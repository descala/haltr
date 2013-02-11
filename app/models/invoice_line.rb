class InvoiceLine < ActiveRecord::Base

  unloadable

  UNITS     = 1
  HOURS     = 2
  KILOGRAMS = 3
  LITTERS   = 4
  DAYS      = 5

  UNIT_CODES = {
    UNITS     => {:name => 'units',     :facturae => '01', :ubl => 'C62'},
    HOURS     => {:name => 'hours',     :facturae => '02', :ubl => 'HUR'},
    KILOGRAMS => {:name => 'kilograms', :facturae => '03', :ubl => 'KGM'},
    LITTERS   => {:name => 'litters',   :facturae => '04', :ubl => 'LTR'},
    DAYS      => {:name => 'days',      :facturae => '05', :ubl => 'DAY'},
  }

  attr_protected :created_at, :updated_at

  belongs_to :invoice
  has_many :taxes, :class_name => "Tax", :order => "percent", :dependent => :destroy
  validates_presence_of :description, :unit
  validates_numericality_of :quantity, :price
  attr_accessor :new_and_first

  # remove colons "1,23" => "1.23"
  def price=(v)
    write_attribute :price, (v.is_a?(String) ? v.gsub(',','.') : v)
  end

  # remove colons "1,23" => "1.23"
  def quanity=(v)
    write_attribute :quantity, (v.is_a?(String) ? v.gsub(',','.') : v)
  end

  def initialize(attributes=nil)
    super
    update_currency
  end

  def total
    Money.new((price * quantity * Money::Currency.new(currency).subunit_to_unit).round.to_i, currency)
  end

  def taxable_base
    if invoice.discount_percent
      total * ( 1 - invoice.discount_percent / 100.0)
    else
      total
    end
  end

  def to_label
    description
  end

  def template_replacements(date=nil)
    Utils.replace_dates! description, (date || Date.today) +  (invoice.frequency || 0).months
  end

  def has_tax?(tax_type)
    return true if tax_type.nil?
    taxes.each do |tax|
      return true if tax.name == tax_type.name and tax.percent == tax_type.percent
    end
    false
  end

  def self.units
    UNIT_CODES.collect { |k,v|
      [l(v[:name]), k]
    }
  end

  def unit_code(format)
    UNIT_CODES[unit][format]
  end

  def unit_short
    l("s_#{UNIT_CODES[unit][:name]}")
  end

  def attributes=(args)
    self.taxes=[]
    args.each do |k,v|
      # k = 'tax_VAT' = name
      # v = '10.0_AA' = percent + category
      if k =~ /^tax_([a-zA-Z]+)$/
        name = $1
        percent, category = v.split('_')
        comment = ""
        # if tax is exempt, copy exempt reason from tax definition on company
        if category == "E"
          tax_template = invoice.company.taxes.find(:first,
            :conditions => ["name=? AND category=? AND percent=0",name,category])
          comment = tax_template.comment if tax_template
        end
        self.taxes << Tax.new(:name=>name,
                              :category=>category,
                              :percent=>percent.to_f,
                              :comment=>comment)
        args.delete k
      end
    end
    super
  end

  def taxes_withheld
    taxes.find(:all, :conditions => "percent < 0")
  end

  def taxes_outputs
    taxes.find(:all, :conditions => "percent >= 0")
  end

  private

  def update_currency
    self.currency = self.invoice.currency rescue nil
    self.currency ||= self.invoice.client.currency rescue nil
    self.currency ||= self.invoice.company.currency rescue nil
    self.currency ||= Setting.plugin_haltr['default_currency']
  end

  def method_missing(m, *args)
    if m.to_s =~ /^tax_[a-zA-Z]+/ and args.size == 0
      curr_tax = taxes.collect do |t|
        t if t.name == m.to_s.gsub(/tax_/,'')
      end.compact.first
      return curr_tax.nil? ? nil : curr_tax.code
    else
      super
    end
  end

end

