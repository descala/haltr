# to draw states graph execute:
#   rake state_machine:draw FILE=invoice.rb CLASS=IssuedInvoice ORIENTATION=landscape
class IssuedInvoice < InvoiceDocument

  unloadable

  belongs_to :invoice_template
  validates_presence_of :number, :unless => Proc.new {|invoice| invoice.type == "DraftInvoice"}
  validates_presence_of :due_date
  validates_uniqueness_of :number, :scope => [:project_id,:type], :if => Proc.new {|i| i.type == "IssuedInvoice" }
  validate :invoice_must_have_lines

  before_validation :set_due_date
  before_save :update_imports
  after_create :create_event
  after_destroy :release_amended
  before_save :update_status, :unless => Proc.new {|invoicedoc| invoicedoc.state_changed? }

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
      transition [:sent,:refused] => :accepted
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

  def self.find_can_be_sent(project)
    project.issued_invoices.all :conditions => ["state='new' and number is not null and date <= ?", Date.today], :order => "number ASC"
  end

  def self.find_not_sent(project)
    project.issued_invoices.all :conditions => "state='new' and number is not null", :order => "number ASC"
  end

  def self.candidates_for_payment(payment)
    # order => older invoices to get paid first
    find :all, :conditions => ["project_id = ? and total_in_cents = ? and date <= ? and state != 'closed'", payment.project_id, payment.amount_in_cents, payment.date], :order => "due_date ASC"
  end

  def past_due?
    !state?(:closed) && due_date && due_date < Date.today
  end

  def self.past_due_total(project)
    IssuedInvoice.sum :total_in_cents, :conditions => ["state <> 'closed' and due_date < ? and project_id = ?", Date.today, project.id]
  end

  def can_be_exported?
    # TODO Test if endpoint is correcty configured
    return @can_be_exported unless @can_be_exported.nil?
    @can_be_exported = self.valid? and ExportChannels.folder(client.invoice_format) != nil
    ExportChannels.validations(client.invoice_format).each do |v|
      can = self.send(v)
      @can_be_exported &&= can
    end
    @can_be_exported
  end

  def self.last_number(project)
    i = IssuedInvoice.last(:order => "number", :conditions => ["project_id = ?", project.id])
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

  def sending_info
    return export_errors.collect {|e| e}.join(", ") if export_errors and export_errors.size > 0
    if %w(ublinvoice_20 facturae_30 facturae_31 facturae_32 signed_pdf svefaktura peppolbii peppol oioubl20).include?(client.invoice_format)
      return "recipients:\n#{self.recipient_emails.join("\n")}"
    end
    ""
  end

  # stores the email in the draft folder of an email account
  def store_imap_draft_pdf(pdf_file_path, channel_params)
    message = InvoiceMailer.create_issued_invoice_mail(self, {:pdf_file_path=>pdf_file_path, :from => channel_params['imap_from']})
    #TODO move imap parameters to Company
    Haltr::IMAP.store_draft(:host=>company.imap_host,
                            :imap_port=>company.imap_port,
                            :imap_ssl=>company.imap_ssl,
                            :username=>company.imap_username,
                            :password=>company.imap_password,
                            :message=>message)
  end

  def valid_payment_method
    valid_payment_method = true
    if debit?
      c = Client.find client_id
      if c.bank_account.blank? and !c.use_iban?
        add_export_error("#{l(:field_payment_method)} (#{l(:debit)}) #{l(:requires_client_bank_account)}")
        valid_payment_method = false
      end
    elsif transfer?
      if company.bank_account.blank? and !company.use_iban?
        add_export_error("#{l(:field_payment_method)} (#{l(:transfer)}) #{l(:requires_company_bank_account)}")
        valid_payment_method = false
      end
    end
    valid_payment_method
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
    if self.recipient_emails.any?
      true
    else
      add_export_error(l(:client_has_no_email))
      false
    end
  end

  def company_has_imap_config
    company and
      !company.imap_host.blank? and
      !company.imap_username.blank? and
      !company.imap_password.blank? and
      !company.imap_port.nil?
  end

  # facturae 3.x needs taxes to be valid
  # but now we always force a 0.00 tax in the template, so it will always have taxes
  def invoice_has_taxes
    true
  end

  def ubl_invoice_has_no_taxes_withheld
    if self.taxes_withheld.any?
      add_export_error(l(:ubl_invoice_has_taxes_withheld))
      false
    else
      true
    end
  end

  def peppol_fields
    if self.client.schemeid.blank? or self.client.endpointid.blank?
      add_export_error(l(:missing_client_peppol_fields))
      return false
    elsif self.company.schemeid.blank? or self.company.endpointid.blank?
      add_export_error(l(:missing_company_peppol_fields))
      return false
    end
    true
  end

  def svefaktura_fields
   if self.respond_to?(:accounting_cost) and self.accounting_cost.blank?
      add_export_error(l(:missing_svefaktura_account))
      return false
   elsif self.company.company_identifier.blank?
      add_export_error(l(:missing_svefaktura_organization))
      return false
   elsif self.debit?
      add_export_error(l(:missing_svefaktura_debit))
      return false
    end
    true
  end

  def oioubl20_fields
  end

  def release_amended
    if self.amend_of
      self.amend_of.amend_id = nil
      self.amend_of.save
    end
  end

  def update_status
    update_imports
    if is_paid?
      if (state?(:sent) or state?(:accepted) or state?(:allegedly_paid))
        paid
      end
    else
      unpaid if state?(:closed)
    end
    return true # always continue saving
  end

end
