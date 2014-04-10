class HaltrMailer < ActionMailer::Base
  layout 'mailer'
  helper :application
  helper :haltr

  unloadable
  include Redmine::I18n
  require "digest/md5"

  def self.default_url_options
    { :host => Setting.host_name, :protocol => Setting.protocol }
  end

  # Builds a Mail::Message object used to email recipients of the invoice.
  #
  # Example:
  #   send_invoice(invoice,options) => Mail::Message object
  #   HaltrMailer.send_invoice(invoice,{:pdf=>pdf}).deliver => sends an email to invoice recipients
  def send_invoice(invoice, options={})
    pdf  = options[:pdf]
    from = options[:from] || "#{invoice.company.name.gsub(',','')} <#{invoice.company.email}>"
    @invoice = invoice
    @invoice_url = invoice_public_view_url(:invoice_id=>invoice.id,
                                           :client_hashid=>invoice.client.hashid)
    set_language_if_valid invoice.client.language
    filename = "#{I18n.t(:label_invoice)}_#{invoice.number.gsub(/[^\w]/,'_')}.pdf" rescue "Invoice.pdf"
    haltr_headers 'Id'       => invoice.id,
                  'MD5'      => Digest::MD5.hexdigest(pdf),
                  'Filename' => filename

    attachments[filename] = pdf

    recipients = invoice.recipient_emails.join(', ')
    bcc  = invoice.company.email
    #TODO: define allowed methods here for safety
    subj = Setting.plugin_haltr['invoice_mail_subject'].gsub(/@invoice\.(\w+)/) {|s|
      @invoice.send($1) rescue s
    }.gsub(/@client\.(\w+)/) {|s|
      @invoice.client.send($1) rescue s
    }

    mail :to   => recipients,
      :subject => subj,
      :from    => from,
      :bcc     => bcc
  end

  def mail(headers={})
    headers.merge! 'X-Mailer' => 'Haltr',
      'X-Redmine-Host' => Setting.host_name,
      'X-Redmine-Site' => Setting.app_title

    haltr_headers 'Sender' => User.current.id

#    # Blind carbon copy recipients
#    if Setting.bcc_recipients?
#      headers[:bcc] = [headers[:to], headers[:cc]].flatten.uniq.reject(&:blank?)
#      headers[:to] = nil
#      headers[:cc] = nil
#    end

    super headers do |format|
      format.text
      format.html unless Setting.plain_text_mail?
    end

    set_language_if_valid @initial_language
  end

  def initialize(*args)
    @initial_language = current_language
    super
  end

  def self.deliver_mail(mail)
    return false if mail.to.blank? && mail.cc.blank? && mail.bcc.blank?
    super
  end

  def self.method_missing(method, *args, &block)
    if m = method.to_s.match(%r{^deliver_(.+)$})
      ActiveSupport::Deprecation.warn "Mailer.deliver_#{m[1]}(*args) is deprecated. Use Mailer.#{m[1]}(*args).deliver instead."
      send(m[1], *args).deliver
    else
      super
    end
  end

  private

  # Appends a Haltr header field (name is prepended with 'X-Haltr-')
  def haltr_headers(h)
    h.each { |k,v| headers["X-Haltr-#{k}"] = v.to_s }
  end

end
