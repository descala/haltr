# == Schema Information
# Schema version: 20091016144057
#
# Table name: invoices
#
#  id                  :integer(4)      not null, primary key
#  client_id           :integer(4)
#  date                :date
#  number              :string(255)
#  extra_info          :text
#  terms               :string(255)
#  created_at          :datetime
#  updated_at          :datetime
#  discount_text       :string(255)
#  discount_percent    :integer(4)
#  draft               :boolean(1)
#  type                :string(255)
#  frequency           :integer(4)
#  invoice_template_id :integer(4)
#  status              :integer(4)      default(1)
#  due_date            :date
#  use_bank_account    :boolean(1)      default(TRUE)
#

class InvoiceTemplate < Invoice

  unloadable

  has_many :invoice_documents, :dependent => :nullify
  validates_presence_of :frequency

  def next_invoice
    i = InvoiceDocument.new self.attributes
    i.number = InvoiceDocument.next_number
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
