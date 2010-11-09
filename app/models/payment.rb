class Payment < ActiveRecord::Base

  unloadable

  belongs_to :invoice
  belongs_to :project
  validates_numericality_of :amount_in_cents, :greater_than => 0

  def initialize(attributes=nil)
    super
    self.date ||= Date.today
  end

  def description
    desc = ""
    desc += "#{self.payment_method} - " unless self.payment_method.nil? or self.payment_method.blank?
    desc += self.reference
  end

  def after_save
    return unless invoice
    unless invoice.unpaid > 0 and invoice.status < Invoice::STATUS_CLOSED
      invoice.status = Invoice::STATUS_CLOSED
      invoice.save
    end
  end

  def after_destroy
    return unless invoice
    if invoice.unpaid > 0 and invoice.status == Invoice::STATUS_CLOSED
      invoice.status = Invoice::STATUS_SENT
      invoice.save
    end
  end

end
