class InvoiceDocument < Invoice

  unloadable

  belongs_to :invoice_template
  has_many :payments, :foreign_key => :invoice_id, :dependent => :nullify
  validates_presence_of :number, :due_date
  validate :number_must_be_unique_in_project
  validate :invoice_must_have_lines

  before_save :update_status, :unless => Proc.new {|invoicedoc| invoicedoc.state_changed? }

  # new sending sent error discarded closed
  state_machine :state, :initial => :new do
    before_transition :on => :queue, :do => :create_b2b_message
    before_transition :on => :requeue, :do => :update_b2b_message
    event :manual_send do
      transition [:new,:sending,:error,:discarded] => :sent
    end
    event :queue do
      transition :new => :sending
    end
    event :requeue do
      transition [:sent,:error,:discarded] => :sending
    end
    event :success_sending do
      transition [:sending,:error] => :sent
    end
    event :mark_unsent do
      transition [:sent,:closed,:error,:discarded] => :new
    end
    event :error_sending do
      transition :sending => :error
    end
    event :close do
      transition [:sent] => :closed
    end
    event :discard do
      transition [:error,:sending] => :discarded
    end
  end

  def sent?
    state?(:sent) or state?(:closed)
  end

  def self.find_due_dates(project)
    find_by_sql "SELECT due_date, invoices.id, count(*) AS invoice_count FROM invoices, clients WHERE type='InvoiceDocument' AND client_id = clients.id AND clients.project_id = #{project.id} AND state = 'sent' AND bank_account AND payment_method=#{Invoice::PAYMENT_DEBIT} GROUP BY due_date"
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
    find :all, :include => [:client], :conditions => ["clients.project_id = ? and state = 'new' and draft != ?", project.id, 1 ]
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
    find :all, :conditions => ["round(import_in_cents*(1+tax_percent/100)) = ? and date <= ? and state != 'closed'", payment.amount_in_cents, payment.date], :order => "due_date ASC"
  end

  def batchidentifier
    require "digest/md5"
    Digest::MD5.hexdigest("#{client.project_id}#{date}#{number}")
  end

  # Insert invoice into b2brouter messages database, if not exists
  def create_b2b_message
    b2bm = b2b_message
    if b2bm
      update_b2b_message
    else
      @b2bmessage=B2bMessage.new(:md5=>md5,:name=>filename,:b2b_channel_id=>channel)
      @b2bmessage.save
      @b2bmessage
    end
  rescue Exception => e
    #TODO
    logger.error(e.message)
    nil
  end

  def update_b2b_message
    b2bm = b2b_message
    b2bm = create_b2b_message unless b2bm
    return unless b2bm
    b2bm.sent = nil
    b2bm.save
  end

  def b2b_message
    logger.info("Aprofitant @b2bmessage") if @b2bmessage
    return @b2bmessage if @b2bmessage
    B2bMessage.connect(b2brouter_url)
    b=B2bMessage.find(:by_channel_and_md5, :params => { :b2b_channel=>channel, :md5=>md5 })
    @b2bmessage = b if b.exists?
    @b2bmessage
  rescue Exception => e
    #TODO
    logger.error(e.message)
    nil
  end

  def b2brouter_url
    read_attribute(:b2brouter_url).blank? ? Setting.plugin_haltr['trace_url'] : read_attribute(:b2brouter_url)
  end

  protected

  def update_status
    self.state='sent' if state?(:closed) && !paid?
    self.state='closed' if paid?
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
