class Company < ActiveRecord::Base

  unloadable

  belongs_to :project
  validates_presence_of :name, :project_id
  validates_length_of :taxid, :maximum => 9
  validates_numericality_of :bank_account
  validates_length_of :bank_account, :maximum => 20

  def initialize(attributes=nil)
    super
    self.withholding_tax_name ||= "IRPF"
  end

  def <=>(oth)
    self.name <=> oth.name
  end

  def first_name
    name.split(" ").first
  end

  def last_name
    ln = name.split(" ")
    ln.shift
    ln.join(" ")
  end

end
