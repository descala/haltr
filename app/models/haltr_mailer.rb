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
    xml  = options[:xml]
    from = options[:from] || "#{invoice.company.name.gsub(',','')} <#{invoice.company.email}>"
    reply_to = options[:reply_to] || "#{invoice.company.name.gsub(',','')} <#{invoice.company.email}>"
    @invoice = invoice
    @invoice_url = invoice_public_view_url(:invoice_id=>invoice.id,
                                           :client_hashid=>invoice.client.hashid)
    set_language_if_valid invoice.client.language
    haltr_headers 'Id'  => invoice.id
    label = I18n.t(invoice.is_a?(Quote) ? :label_quote : :label_invoice)

    if pdf
      pdf_filename = "#{label}-#{invoice.number.gsub(/[^\w]/,'')}.pdf" rescue "#{label}.pdf"
      haltr_headers 'PDF-Filename' => pdf_filename if pdf
      attachments[pdf_filename] = pdf
      haltr_headers 'PDF-MD5' => Digest::MD5.hexdigest(pdf)
    end

    if xml
      xml_filename = "#{label}-#{invoice.number.gsub(/[^\w]/,'')}.xml" rescue "#{label}.xml"
      haltr_headers 'XML-Filename' => xml_filename if xml
      attachments[xml_filename] = xml
      haltr_headers 'XML-MD5' => Digest::MD5.hexdigest(xml)
    end

    recipients = invoice.recipient_emails.join(', ')
    bcc        = invoice.company.email
    subj       = ""
    @body      = ""
    if @invoice.is_a?(Quote)
      subj  = @invoice.company.quote_mail_subject(@invoice.client.language,@invoice)
      @body = @invoice.company.quote_mail_body(@invoice.client.language,@invoice)
    else
      subj  = @invoice.company.invoice_mail_subject(@invoice.client.language,@invoice)
      @body = @invoice.company.invoice_mail_body(@invoice.client.language,@invoice)
    end

    unless Setting.plugin_haltr['return_path'].blank?
      headers['Return-Path'] = Setting.plugin_haltr['return_path']
    end

    mail :to   => recipients,
      :subject => subj,
      :from    => from,
      :bcc     => bcc,
      :reply_to => reply_to
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
