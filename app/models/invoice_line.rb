class InvoiceLine < ActiveRecord::Base

  include Haltr::FloatParser
  float_parse :discount_percent, :price, :quantity, :charge

  audited :associated_with => :invoice, :except => [:id, :invoice_id]
  has_associated_audits


  UNITS     = 1
  HOURS     = 2
  KILOGRAMS = 3
  LITTERS   = 4
  DAYS      = 5
  OTHER     = 6
  BOXES     = 7

  UNIT_CODES = {
    UNITS     => { name: 'units',     facturae: '01', ubl: 'C62', edifact: 'EA' },
    HOURS     => { name: 'hours',     facturae: '02', ubl: 'HUR', edifact: 'PCE'},
    KILOGRAMS => { name: 'kilograms', facturae: '03', ubl: 'KGM', edifact: 'KGM'},
    LITTERS   => { name: 'litters',   facturae: '04', ubl: 'LTR', edifact: 'LTR'},
    OTHER     => { name: 'other',     facturae: '05', ubl: 'ZZ',  edifact: 'OTH'},
    DAYS      => { name: 'days',      facturae: '05', ubl: 'DAY', edifact: 'PCE'},
    BOXES     => { name: 'boxes',     facturae: '06', ubl: 'CS',  edifact: 'CS' },
  }

  # do not remove, with audit we need to make the other attributes accessible
  attr_protected :created_at, :updated_at

  belongs_to :invoice
  has_many :taxes, -> {order :percent}, :class_name => "Tax", :dependent => :destroy
  validates_numericality_of :quantity, :price
  validates_numericality_of :charge, :discount_percent, :position, :allow_nil => true
  validates_numericality_of :sequence_number, :allow_nil => true, :allow_blank => true
  validates :description, length: { maximum: 2500 }
  validates :discount_text, length: { maximum: 255 }

  accepts_nested_attributes_for :taxes,
    :allow_destroy => true
  validates_associated :taxes
  validate :has_same_category_iva_tax, if: Proc.new {|line| line.taxes.any? {|t| t.name == 'RE' } }

  scope :sorted, lambda { order("#{table_name}.position ASC") }

  # Coste Total.
  # Quantity x UnitPriceWithoutTax
  def total_cost
    quantity * price
  end

  # Importe bruto.
  # TotalCost - DiscountAmount + ChargeAmount
  def gross_amount
    taxable_base
  end

  def taxable_base
    total_cost - discount_amount + charge
  end

  # warn! this tax_amount does not include global discounts.
  def tax_amount(tax)
    taxable_base * (tax.percent.to_f / 100.0)
  end

  def discount_amount
    if self[:discount_amount] and self[:discount_amount] != 0
      self[:discount_amount]
    elsif self[:discount_percent] and self[:discount_percent] != 0
      total_cost * (self[:discount_percent] / 100.0)
    else
      0
    end
  end

  def discount_percent
    if self[:discount_percent] and self[:discount_percent] != 0
      self[:discount_percent]
    elsif self[:discount_amount] and self[:discount_amount] != 0
      self[:discount_amount] * 100 / total_cost
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
  rescue
    if format == :ubl
      'EA'
    else
      nil
    end
  end

  def unit_short
    l("s_#{UNIT_CODES[unit][:name]}") rescue unit
  end

  def taxes_withheld
    taxes.select {|t| t.percent.to_f < 0 }
  end

  def taxes_outputs
    taxes.select {|t| t.percent.to_f >= 0 }
  end

  def exempt_taxes
    taxes.select do |t|
      t.exempt?
    end
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

  def has_same_category_iva_tax
    re_taxes = taxes.select {|t| t.name == 'RE' }
    iva_taxes = taxes.select {|t| t.name == 'IVA' }
    re_taxes.each do |tax|
      next if tax.marked_for_destruction?
      unless iva_taxes.any? {|t| t.category == tax.category }
        errors.add(:base, l(:re_tax_without_iva_same_category, :line => description))
      end
    end
  end

  def <=>(line)
    position <=> line.position
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

  # translations for accepts_nested_attributes_for
  def self.human_attribute_name(attribute_key_name, *args)
    super(attribute_key_name.to_s.gsub(/taxes\./,''), *args)
  end

end

