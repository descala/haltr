class InvoiceTemplate < Invoice



  has_many :issued_invoices, :dependent => :nullify
  validates_presence_of :frequency
  validate :invoice_must_have_lines

  before_validation :set_due_date
  before_save :update_imports

  def invoices_until(date_limit)
    drafts = []
    while self.date <= date_limit
      # TODO: invoice numbers do not grow with invoice dates
      # if we generate many invoices for the same template
      drafts << next_invoice
    end
    drafts
  end

  def next_invoice
    i = DraftInvoice.new self.attributes
    i.invoice_template = self
    i.state = 'new'
    # Do not generate invoices on weekend
    if [6,0].include? i.date.wday
      i.date = i.date.next_week
    end
    template_replacements(i.date)
    # copy template lines
    self.invoice_lines.each do |tl|
      l = InvoiceLine.new tl.attributes
      l.template_replacements(i.date)
      i.invoice_lines << l
      tl.taxes.each do |tax|
        l.taxes << Tax.new(tax.attributes.except('invoice_line_id'))
      end
    end
    i.save!
    self.date = self.date.to_time.months_since(self.frequency).to_date
    if self.terms == "custom" and self.due_date
      self.due_date = self.due_date.to_time.months_since(self.frequency).to_date
    end
    self.save!
    return i
  rescue ActiveRecord::RecordInvalid
    raise i.errors.full_messages.join(', ')
  end

  def label
    l(:label_invoice_template)
  end

  def to_s
    self.id.to_s
  end

  def template_replacements(date=nil)
    Utils.replace_dates! extra_info, (date || Date.today) +  (frequency || 0).months
  end

  def past_due?
    false
  end

  def invoice_img
    nil
  end

  def number
    date
  end

  def payments
    []
  end
end
