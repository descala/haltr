class Company < ActiveRecord::Base

  unloadable

  belongs_to :project
  validates_presence_of :name, :project_id
  validates_length_of :taxid, :maximum => 9
  validates_numericality_of :bank_account, :allow_nil => true, :unless => Proc.new {|company| company.bank_account.blank?}
  validates_length_of :bank_account, :maximum => 20
  validates_inclusion_of :currency, :in  => Money::Currency::TABLE.collect {|k,v| v[:iso_code] }
  validates_uniqueness_of :taxid
  acts_as_attachable :view_permission => :free_use,
                     :delete_permission => :free_use

  def initialize(attributes=nil)
    super
    self.withholding_tax_name ||= "IRPF"
    self.currency ||= Money.default_currency.iso_code
    self.attachments ||= []
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

  def currency=(v)
    write_attribute(:currency,v.upcase)
  end

end
