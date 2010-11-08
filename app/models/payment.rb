class Payment < ActiveRecord::Base

  unloadable

  belongs_to :invoice
  belongs_to :project

  def initialize(attributes=nil)
    super
    self.date ||= Date.today
  end

  def description
    desc = ""
    desc += "#{self.payment_method} - " unless self.payment_method.nil? or self.payment_method.blank?
    desc += self.reference
  end

end
