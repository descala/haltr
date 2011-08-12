class Tax < ActiveRecord::Base

  unloadable

  belongs_to :company
  has_and_belongs_to_many :invoices
  validates_presence_of :name, :percent
  validates_numericality_of :percent
  # only one name-percent combination per company:
  validates_uniqueness_of :percent, :scope => [:company_id,:name]

end
