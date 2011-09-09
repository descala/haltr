class Tax < ActiveRecord::Base

  unloadable

  belongs_to :company
  validates_presence_of :name, :percent
  validates_numericality_of :percent
  validates_format_of :name, :with => /^[a-zA-Z]+$/
  # only one name-percent combination per invoice_line:
  validates_uniqueness_of :percent, :scope => [:invoice_line_id,:name], :unless => Proc.new { |tax| tax.invoice_line_id.nil? }
  # only one name-percent combination per company:
  validates_uniqueness_of :percent, :scope => [:company_id,:name], :unless => Proc.new { |tax| tax.company_id.nil? }

  def ==(oth)
    self.name == oth.name and self.percent == oth.percent
  end

end
