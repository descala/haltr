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

  accepts_nested_attributes_for :taxes,
    :allow_destroy => true
  validates_associated :taxes

  # remove colons "1,23" => "1.23"
  def price=(v)
    write_attribute :price, (v.is_a?(String) ? v.gsub(',','.') : v)
  end

  # remove colons "1,23" => "1.23"
  def quanity=(v)
    write_attribute :quantity, (v.is_a?(String) ? v.gsub(',','.') : v)
  end

  def total
    Money.new((price * quantity * Money::Currency.new(invoice.currency).subunit_to_unit).round.to_i, invoice.currency)
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
      return true if tax == tax_type
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

  def taxes_withheld
    taxes.find(:all, :conditions => "percent < 0")
  end

  def taxes_outputs
    taxes.find(:all, :conditions => "percent >= 0")
  end

  def to_s
    taxes_string = taxes.collect do |tax|
      tax.to_s
    end.join("\n").gsub(/\n$/,'')
    <<_LINE
  * #{quantity} x #{description} #{price}
#{taxes_string}
_LINE
  end

  private

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

