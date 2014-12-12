class Discount < ActiveRecord::Base

  unloadable
  audited :associated_with => :invoice_line, :except => [:id, :invoice_line_id]
  attr_protected :created_at, :updated_at

  belongs_to :invoice_line
  validates_numericality_of :percent

end
