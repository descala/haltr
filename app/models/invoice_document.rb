class InvoiceDocument < Invoice

  unloadable

  has_many :payments, :foreign_key => :invoice_id, :dependent => :destroy
  has_one :invoice_img, :foreign_key => 'invoice_id'

  attr_accessor :legal_filename, :legal_content_type, :legal_invoice

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

  def original=(s)
    write_attribute(:original, Haltr::Utils.compress(s))
  end

  def original
    Haltr::Utils.decompress(read_attribute(:original))
  end

  # https://rails.lighthouseapp.com/projects/8994/tickets/2389-sti-changes-behavior-depending-on-environment
  # must be at the bottom of class
  %w(received_invoice issued_invoice).each do |r| 
    require_dependency r
  end if Rails.env.development?

end

