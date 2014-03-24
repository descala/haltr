class HaltrMailer < ActionMailer::Base
  layout 'mailer'
  helper :application

  unloadable
  include Redmine::I18n
  require "digest/md5"

  def self.default_url_options
    { :host => Setting.host_name, :protocol => Setting.protocol }
  end

  # Builds a Mail::Message object used to email recipients of the invoice.
  #
  # Example:
  #   invoice(invoice,pdf) => Mail::Message object
  #   HaltrMailer.send_invoice(invoice,pdf).deliver => sends an email to invoice recipients
  def send_invoice(invoice, pdf)
    @invoice = invoice
    @invoice_url = invoice_public_view_url(:invoice_id=>invoice.id,
                                           :client_hashid=>invoice.client.hashid)
    set_language_if_valid invoice.client.language
    filename = "#{I18n.t(:label_invoice)}_#{invoice.number.gsub(/[^\w]/,'_')}.pdf" rescue "Invoice.pdf"
    haltr_headers 'Id'       => invoice.id,
                  'MD5'      => Digest::MD5.hexdigest(pdf),
                  'Filename' => filename

    attachments[filename] = pdf

    mail :to      => invoice.client.email,
         :subject => Setting.plugin_haltr['invoice_mail_subject'],
         :from    => invoice.company.email
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

  # delayed_job hooks
  def self.success(job)
    Event.create!(:name    => 'success_sending',
                  :invoice => job.payload_object.args.first,
                  :info    => job.payload_object.args.last)
  end

  def self.failure(job)
    Event.create!(:name    => 'discard_sending',
                  :invoice => job.payload_object.args.first,
                  :info    => job.payload_object.args.last)
  end

  private

  # Appends a Haltr header field (name is prepended with 'X-Haltr-')
  def haltr_headers(h)
    h.each { |k,v| headers["X-Haltr-#{k}"] = v.to_s }
  end

end
