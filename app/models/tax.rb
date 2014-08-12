class Tax < ActiveRecord::Base

  unloadable
  audited :associated_with => :invoice_line, :except => [:id, :invoice_line_id]

  # do not remove, with audit we need to make the other attributes accessible
  attr_protected :created_at, :updated_at

  belongs_to :company
  belongs_to :invoice_line
  validates_presence_of :name
  validates_numericality_of :percent,
    :unless => Proc.new { |tax| tax.category == "E" }
  validates_format_of :name, :with => /^[a-zA-Z]+$/
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
    :if => Proc.new { |tax| ["Z","E"].include? tax.category }

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
    category == "E"
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
    self.percent=p
    self.category=c
  end

  # E=Exempt, Z=ZeroRated, S=Standard, H=High Rate, AA=Low Rate
  def self.categories
    ['E','Z','S','H','AA']
  end

  def to_s
    <<_TAX
    - #{name} #{code} #{category} #{comment}
_TAX
  end

end
