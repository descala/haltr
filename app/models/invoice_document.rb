class InvoiceDocument < Invoice



  has_many :payments, :foreign_key => :invoice_id, :dependent => :destroy
  has_one :invoice_img, :foreign_key => :invoice_id, :dependent => :destroy

  attr_accessor :legal_filename, :legal_content_type, :legal_invoice

  include AASM

  aasm column: :state, skip_validation_on_save: true, whiny_transitions: false do
    state :new, initial: true
    state :sending, :sent, :read, :error, :closed, :discarded, :accepted,
      :refused, :registered, :allegedly_paid, :cancelled, :annotated,
      :processing_pdf, :paid
    state :received

    before_all_events :aasm_create_event
    after_all_transitions :update_state_updated_at

    event :manual_send do
      transitions from: [:new,:sending,:error,:discarded], to: :sent
    end
    event :queue do
      transitions from: [:new, :error, :discarded, :refused], to: :sending
    end
    event :success_sending do
      transitions from: [:new,:sending,:error,:discarded], to: :sent
    end
    event :mark_unsent do
      transitions from: [:sent,:read,:sending,:closed,:error,:discarded], to: :new
    end
    event :error_sending do
      transitions from: :sending, to: :error
    end
    event :close do
      transitions from: [:new,:sent,:read,:registered], to: :closed
    end
    event :discard_sending do
      transitions from: [:error,:sending], to: :discarded
    end
    event :accept do
      transitions to: :accepted
    end
    event :paid do
      transitions from: [:sent,:read,:accepted,:allegedly_paid,:registered], to: :closed
    end
    event :unpaid do
      transitions from: :closed, to: :sent
    end
    event :bounced do
      transitions from: :sent, to: :discarded
    end
    event :accept_notification do
      transitions to: :accepted
    end
    event :refuse_notification do
      transitions to: :refused
    end
    event :paid_notification do
      transitions to: :allegedly_paid
    end
    event :sent_notification do
      transitions from: :sent, to: :sent
    end
    event :delivered_notification do
      transitions from: :sent, to: :sent
    end
    event :registered_notification do
      transitions to: :registered
    end
    event :amend_and_close do
      transitions to: :closed
    end
    event :processing_pdf do
      transitions from: :new, to: :processing_pdf
    end
    event :processed_pdf do
      transitions from: :processing_pdf, to: :new
    end
    event :mark_as_new do
      transitions to: :new
    end
    event :mark_as_sent do
      transitions to: :sent
    end
    event :mark_as_accepted do
      transitions to: :accepted
    end
    event :mark_as_registered do
      transitions to: :registered
    end
    event :mark_as_refused do
      transitions to: :refused
    end
    event :mark_as_closed do
      transitions to: :closed
    end
    event :mark_as_paid do
      transitions to: :paid
    end
    event :read do
      transitions from: [:received, :sent], to: :read
    end
    event :received_notification do
      transitions to: :read
    end
    event :failed_notification do
      transitions to: :error
    end
    event :cancelled_notification do
      transitions to: :cancelled
    end
    event :annotated_notification do
      transitions to: :annotated
    end
  end

  def self.states
    aasm.states.map(&:name)
  end

  def initial_md5
    self.events.collect {|e| e unless e.md5.blank? }.compact.sort.last.md5 rescue nil
  end

  # retrieve invoice from external system
  # to allow to download a modified invoice file
  # (for example digitally signed file)
  def fetch_from_backup(md5=nil,backup_name=nil)
    md5 ||= self.initial_md5
    url = Setting.plugin_haltr["trace_url"]
    url = URI.parse(url.gsub(/\/$/,'')) # remove trailing slash
    connection = Net::HTTP.new(url.host,url.port)
    connection.start() do |http|
      full_url = "#{url.path.blank? ? "/" : "#{url.path}/"}b2b_messages/get_backup?md5=#{md5}&name=#{backup_name}"
      logger.debug "Fetching backup GET #{full_url}" if logger && logger.debug?
      req = Net::HTTP::Get.new(full_url)
      response = http.request(req)
      if response.is_a? Net::HTTPOK
        # retrieve filename from response headers
        if response["Content-Disposition"]
          self.legal_filename = response["Content-Disposition"].match('filename=\\".*\\"').to_s.gsub(/filename=/,'').gsub(/\"/,'').gsub(/^legal_/,'')
        else
          self.legal_filename = "invoice.xml"
        end
        self.legal_content_type = response["Content-Type"]
        self.legal_invoice = response.body
        return true
      else
        return false
      end
    end
  rescue Exception => e
    logger.error "Error retrieving invoice #{id} from backup: #{e.message}"
    return false
  end

  def unpaid_amount
    total - total_paid
  end

  def is_paid?
    unpaid_amount.cents == 0
  end

  def total_paid
    paid_amount=0
    self.payments.each do |payment|
      paid_amount += payment.amount.cents
    end
    Money.new(paid_amount,currency)
  end

  # Creates an Event unless it is an "automatic" state change
  def aasm_create_event(user=nil)
    user ||= User.current
    name = aasm.current_event.to_s.gsub('!','')
    unless Event.automatic.include?(name)
      if name == 'queue' and !new?
        Event.create(name: 'requeue', invoice: self, user: user)
      elsif name =~ /^mark_as_/
        Event.create(name: "done_#{name}", invoice: self, user: user)
      else
        Event.create(name: name, invoice: self, user: user)
      end
    end
  end

  def to_label
    "#{number}"
  end

  # if state changes, record state timestamp :state_updated_at
  # an update to an Invoice sets timestamps as usual, except for:
  #  :state
  #  :has_been_read
  #  :state_updated_at
  # these attributes do not change updated_at
  def update_state_updated_at
    write_attribute :state_updated_at, Time.now
  end

end

