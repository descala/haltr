class InvoiceDocument < Invoice

  unloadable

  belongs_to :invoice_template
  has_many :payments, :foreign_key => :invoice_id, :dependent => :nullify
  validates_presence_of :number, :due_date
  validate :number_must_be_unique_in_project
  validate :invoice_must_have_lines

  before_save :update_status, :unless => Proc.new {|invoicedoc| invoicedoc.status_changed? }

  def self.find_due_dates(project)
    find_by_sql "SELECT due_date, invoices.id, count(*) AS invoice_count FROM invoices, clients WHERE type='InvoiceDocument' AND client_id = clients.id AND clients.project_id = #{project.id} AND status = #{Invoice::STATUS_SENT} AND bank_account AND payment_method=#{Invoice::PAYMENT_DEBIT} GROUP BY due_date"
  end

  def label
    if self.draft
      l :label_draft
    else
      l :label_invoice
    end
  end

  def to_label
    "#{number}"
  end

  def self.find_not_sent(project)
    find :all, :include => [:client], :conditions => ["clients.project_id = ? and status = ? and draft != ?", project.id, Invoice::STATUS_NOT_SENT, 1 ]
  end

  def self.count_not_sent(project)
    count :all, :include => [:client], :conditions => ["clients.project_id = ? and status = ? and draft != ?", project.id, Invoice::STATUS_NOT_SENT, 1 ]
  end

  def total_paid
    paid=0
    self.payments.each do |payment|
      paid += payment.amount.cents
    end
    Money.new(paid,currency)
  end

  def unpaid
    total - total_paid
  end

  def paid?
    unpaid.cents <= 0
  end

  def self.candidates_for_payment(payment)
    # order => older invoices to get paid first
    #TODO: add withholding_tax
    find :all, :conditions => ["round(import_in_cents*(1+tax_percent/100)) = ? and date <= ? and status < ?", payment.amount_in_cents, payment.date, STATUS_CLOSED], :order => "due_date ASC"
  end

  def batchidentifier
    require "digest/md5"
    Digest::MD5.hexdigest("#{client.project_id}#{date}#{number}")
  end

  protected

  def update_status
    self.status=STATUS_SENT if status == STATUS_CLOSED && !paid?
    self.status=STATUS_CLOSED if paid?
  end

  def number_must_be_unique_in_project
    return if self.client.nil?
    return if !self.new_record? && !self.number_changed?
    if self.client.project.clients.collect {|c| c.invoice_documents }.flatten.compact.collect {|i| i.number unless i.id == self.id}.include? self.number
      errors.add(:base, ("#{l(:field_number)} #{l(:taken)}"))
    end
  end

  def invoice_must_have_lines
    if invoice_lines.empty? or invoice_lines.all? {|i| i.marked_for_destruction?}
      errors.add(:base, "#{l(:label_invoice)} #{l(:must_have_lines)}")
    end
  end

end
