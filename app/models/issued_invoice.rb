# to draw states graph execute:
#   rake state_machine:draw FILE=invoice.rb CLASS=IssuedInvoice ORIENTATION=landscape
class IssuedInvoice < InvoiceDocument

  unloadable

  belongs_to :invoice_template
  validates_presence_of :number, :unless => Proc.new {|invoice| invoice.type == "DraftInvoice"}
  validates_presence_of :due_date
  validates_uniqueness_of :number, :scope => [:project_id,:type], :if => Proc.new {|i| i.type == "IssuedInvoice" }
  validate :invoice_must_have_lines
  validate :comprovacions_diba
  validate :validate_invoice_semantics

  before_validation :set_due_date
  before_save :update_imports
  after_create :create_event
  after_destroy :release_amended

  attr_accessor :export_errors

  # new sending sent error discarded closed
  state_machine :state, :initial => :new do
    before_transition do |invoice,transition|
      unless Event.automatic.include?(transition.event.to_s)
        Event.create(:name=>transition.event.to_s,:invoice=>invoice,:user=>User.current)
      end
    end
    event :manual_send do
      transition [:new,:sending,:error,:discarded] => :sent
    end
    event :queue do
      transition :new => :sending
    end
    event :requeue do
      transition all - :new => :sending
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
    event :discard_sending do
      transition [:error,:sending] => :discarded
    end
    event :paid do
      transition [:sent,:accepted,:allegedly_paid] => :closed
    end
    event :unpaid do
      transition :closed => :sent
    end
    event :bounced do
      transition :sent => :discarded
    end
    event :accept_notification do
      transition :sent => :accepted
    end
    event :refuse_notification do
      transition :sent => :refused
    end
    event :paid_notification do
      transition :accepted => :allegedly_paid
    end
    event :sent_notification do
      transition :sent => :sent
    end
    event :delivered_notification do
      transition :sent => :sent
    end
    event :registered_notification do
      transition :sent => :sent
    end
    event :amend_and_close do
      transition all=> :closed
    end
  end

  def sent?
    state?(:sent) or state?(:closed)
  end

  # List dates in which invoices are due, an *example* invoice and count
  def self.find_due_dates(project)
    find_by_sql "SELECT due_date, invoices.id, count(*) AS invoice_count FROM invoices, clients WHERE type='IssuedInvoice' AND client_id = clients.id AND clients.project_id = #{project.id} AND state = 'sent' AND bank_account != '' AND invoices.payment_method=#{Invoice::PAYMENT_DEBIT} GROUP BY due_date ORDER BY due_date DESC"
  end

  def label
    if self.amend_of
      l :label_amendment_invoice
    else
      l :label_invoice
    end
  end

  def to_label
    "#{number}"
  end

  def self.find_not_sent(project)
    invoices = find :all, :include => [:client], :conditions => ["clients.project_id = ? and state = 'new'", project.id ], :order => "number ASC"
    invoices.collect do |invoice|
      invoice unless invoice.is_a? DraftInvoice or invoice.number.nil?
    end.compact
  end

  def self.candidates_for_payment(payment)
    # order => older invoices to get paid first
    find :all, :conditions => ["project_id = ? and total_in_cents = ? and date <= ? and state != 'closed'", payment.project_id, payment.amount_in_cents, payment.date], :order => "due_date ASC"
  end

  def past_due?
    !state?(:closed) && due_date && due_date < Date.today
  end

  def can_be_exported?
    # TODO Test if endpoint is correcty configured
    can_be = self.valid? and ExportChannels.channel(client.invoice_format) != nil
    ExportChannels.validations(client.invoice_format).each do |v|
      can_be &&= self.send(v)
    end
    can_be
  end

  def self.last_number(project)
    i = IssuedInvoice.last(:order => "number", :include => [:client], :conditions => ["clients.project_id = ?", project.id])
    i.number if i
  end

  def self.next_number(project)
    number = self.last_number(project)
    self.increment_right(number)
  end

  def self.increment_right(number)
    return "1" if number.nil?
    nums = number.scan(/\d+/).size
    digits = number.scan(/\d+/).last.to_s.size
    return "#{number}1" if nums == 0
    i = 0
    number.gsub(/(\d+)/) do |m|
      i += 1
      if i == nums
        m = sprintf("%0#{digits}d", m.to_i+1)
      else
        m
      end
    end
  end

  def visible_by_client?
    %w(sent refused accepted allegedly_paid closed).include? state
  end

  def create_amend
    new_attributes = self.attributes
    new_attributes['state']='new'
    ai = IssuedInvoice.new(new_attributes)
    ai.number = "#{number}-R"
    ai.save(false)
    self.invoice_lines.each do |line|
      ai.invoice_lines << InvoiceLine.new(line.attributes)
    end
    self.amend_id = ai.id
    self.save(false)
    self.amend_and_close # change state
    ai
  end

  def amended?
    #!amend.nil?
    !self.amend_id.nil?
  end

  def validate_invoice_semantics
    # Can not have lines without tax and a global discount
    if discount.nonzero? and expenses.any?
      errors.add(:base, "#{l(:invoice_no_taxes_and_discount)}")
    end
  end

  protected

  def create_event
    Event.create(:name=>'new',:invoice=>self,:user=>User.current)
  end

  # errors to be raised on sending invoice
  def add_export_error(err)
    @export_errors ||= []
    @export_errors << err
  end

  def client_has_email
    if self.client and !self.client.email.blank?
      true
    else
      add_export_error(:client_has_no_email)
      false
    end
  end

  def comprovacions_diba
    if self.client and self.client.taxcode == Setting.plugin_haltr['diba_cif']
      errors.add(:codi_centre_gestor,:blank) if self.codi_centre_gestor.blank?
    end
  end

  # facturae 3.x needs taxes to be valid
  def invoice_has_taxes
    if self.taxes.any?
      true
    else
      add_export_error(:invoice_has_no_taxes)
      false
    end
  end

  def release_amended
    if self.amend_of
      self.amend_of.amend_id = nil
      self.amend_of.save
    end
  end

end
