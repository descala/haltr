class InvoiceTemplate < Invoice

  unloadable

  has_many :issued_invoices, :dependent => :nullify
  validates_presence_of :frequency

  before_validation :set_due_date
  before_save :update_import

  def next_invoice
    i = IssuedInvoice.new self.attributes
    i.number = IssuedInvoice.next_number(self.project)
    i.tax_percent = Invoice::TAX
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
    end
    if i.save
      self.date = self.date.to_time.months_since(self.frequency)
      self.save!
    end
    return i
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

end
