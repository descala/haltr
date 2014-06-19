class DraftInvoice < IssuedInvoice

  unloadable

  validates_uniqueness_of :date, :scope => :invoice_template_id

  def to_label
    l(:label_draft)
  end

  def can_be_exported?
    false
  end

  protected

  # draft invoices always in "new" state
  def update_status
    return true # always continue saving
  end

  # draft invoices have no number
  def number_must_be_unique_in_project
    return
  end

end
