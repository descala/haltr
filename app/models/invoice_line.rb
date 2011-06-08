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

  belongs_to :invoice
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
    Money.new((price * quantity * 100).round.to_i, currency)
  end

  def to_label
    description
  end

  def template_replacements(date=nil)
    Utils.replace_dates! description, (date || Date.today) +  (invoice.frequency || 0).months
  end

  def tax
     if invoice.tax_percent
      total * (invoice.tax_percent / 100.0)
    else
      Money.new(0,currency)
    end
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

  private

  def update_currency
    self.currency = self.invoice.currency rescue nil
    self.currency ||= self.invoice.client.currency rescue nil
    self.currency ||= self.invoice.company.currency rescue nil
    self.currency ||= Money.default_currency.iso_code
  end

end

