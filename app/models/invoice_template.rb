class InvoiceTemplate < Invoice

  unloadable

  has_many :invoice_documents, :dependent => :nullify
  validates_presence_of :frequency

  def next_invoice
    i = InvoiceDocument.new self.attributes
    i.number = InvoiceDocument.next_number(self.client.project)
    i.tax_percent = Invoice::TAX
    i.invoice_template = self
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
    if i.save!
      self.date = self.date.to_time.months_since(self.frequency)
      self.save!
    end
    return i
  end

  def label
    "Template"
  end

  def to_label
    "Next:#{date}"
  end

  def template_replacements(date=nil)
    Utils.replace_dates! extra_info, (date || Date.today) +  (frequency || 0).months
  end

end
