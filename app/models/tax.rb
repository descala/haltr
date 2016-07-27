class Tax < ActiveRecord::Base


  audited :associated_with => :invoice_line, :except => [:id, :invoice_line_id]

  # do not remove, with audit we need to make the other attributes accessible
  attr_protected :created_at, :updated_at

  belongs_to :company
  belongs_to :invoice_line
  validates_presence_of :name
  validates_numericality_of :percent,
    :unless => Proc.new { |tax| tax.exempt? }
  validates_format_of :name, :with => /\A[a-zA-Z]+\z/
  # only one name-percent combination per invoice_line:
  #TODO: see rails bug https://github.com/rails/rails/issues/4568 on
  # validates_uniqueness_of with accepts_nested_attributes_for
  validates_uniqueness_of :percent, :scope => [:invoice_line_id,:name],
    :unless => Proc.new { |tax| tax.invoice_line_id.nil? or tax.category == "E" }
  # only one name-percent combination per company:
  # see rails bug https://github.com/rails/rails/issues/4568 on
  # validates_uniqueness_of with accepts_nested_attributes_for
  #validates_uniqueness_of :percent, :scope => [:company_id,:name,:category],
  #  :unless => Proc.new { |tax| tax.company_id.nil? }
  validates_numericality_of :percent, :equal_to => 0,
    :if => Proc.new { |tax| ["Z","E","NS"].include? tax.category }

  SPAIN_TAXCODES = {
    'IVA'      => '01', # Impuesto sobre el valor añadido
    'IPSI'     => '02', # Impuesto sobre la producción, los servicios y la importación
    'IGIC'     => '03', # Impuesto general indirecto de Canarias
    'IRPF'     => '04', # Impuesto sobre la Renta de las personas físicas
    'OTRO'     => '05', # Otros
    'ITPAJD'   => '06', # Impuesto sobre transmisiones patrimoniales y actos jurídicos documentados
    'IE'       => '07', # Impuestos especiales
    'RA'       => '08', # Renta aduanas
    'IGTECM'   => '09', # Impuesto general sobre el tráfico de empresas que se aplica en Ceuta y Melilla
    'IECDPCAC' => '10', # Impuesto especial sobre los combustibles derivados del petróleo en la Comunidad Autonoma Canaria
    'IIIMAB'   => '11', # Impuesto sobre las instalaciones que inciden sobre el medio ambiente en la Baleares
    'ICIO'     => '12', # Impuesto sobre las construcciones, instalaciones y obras
    'IMVDN'    => '13', # Impuesto municipal sobre las viviendas desocupadas en Navarra
    'IMSN'     => '14', # Impuesto municipal sobre solares en Navarra
    'IMGSN'    => '15', # Impuesto municipal sobre gastos suntuarios en Navarra
    'IMPN'     => '16', # Impuesto municipal sobre publicidad en Navarra
    'REAV'     => '17', # Regim especial d'IVA de les agencies de viatges (#5492)
    'REIVA'    => '17', # Regim especial d'IVA de les agencies de viatges (#5492)
    'RE'       => '', # Recàrrec d'equivalència (#5560)
  }

  def ==(oth)
    return false if oth.nil?
    self.name == oth.name and
      self.percent == oth.percent and
      self.category == oth.category
  end

  def <=>(oth)
    if (name.to_s <=> oth.name.to_s) == 0
      if percent.nil? and oth.percent.nil?
        category.to_s <=> oth.category.to_s
      elsif percent.nil?
        return -1
      elsif oth.percent.nil?
        return 1
      else
        if percent.abs == oth.percent.abs
          #TODO: sort categories manually
          category.to_s <=> oth.category.to_s
        else
          percent.abs <=> oth.percent.abs
        end
      end
    else
      name.to_s <=> oth.name.to_s
    end
  end

  def exempt?
    category == "E" or category == "NS"
  end

  def zero?
    category == "Z"
  end

  def code
    [percent,category].compact.join("_")
  end

  # sets percent and category from a code string
  def code=(v)
    p, c = v.split("_")
    # workaround for https://github.com/rails/rails/issues/9034
    p='0' if p == '0.0'
    self.percent=p
    self.category=c
  end

  # E=Exempt, NS=NotSubject, Z=ZeroRated, S=Standard, H=High Rate, AA=Low Rate
  def self.categories
    ['E','NS','Z','S','H','AA', 'AAA']
  end

  def to_s
    <<_TAX
    - #{name} #{code} #{category} #{comment}
_TAX
  end

end
