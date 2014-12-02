class InvoiceImg < ActiveRecord::Base
  unloadable

  belongs_to :invoice
  validate :has_associated_invoice

  serialize :data

  def has_associated_invoice
    errors.add(:invoice) unless self.invoice and self.invoice.is_a? InvoiceDocument
  end

  after_create do
    Event.create!(:name=>'processed_pdf',:invoice=>invoice)
    invoice.state='new'
    invoice.save(validate: false)
  end

end
