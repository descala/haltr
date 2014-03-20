class MailNotifier < Mailer
  layout 'mail_notifier'
  helper :haltr
  unloadable

  def received_invoice_accepted(invoice,reason)
    I18n.locale = invoice.client.language
    @invoice = invoice
    @reason = reason
    mail :to => invoice.client.email,
      :from => Setting.mail_from,
      :subject => I18n.t(:received_invoice_accepted,
                         :num => invoice.number,
                         :company => invoice.company.name)
  end

  def received_invoice_refused(invoice,reason)
    I18n.locale = invoice.client.language
    @invoice = invoice
    @reason = reason
    if invoice.fetch_from_backup
      attachments[invoice.legal_filename] = invoice.legal_invoice
    end
    mail :to => invoice.client.email,
      :from => Setting.mail_from,
      :subject => I18n.t(:received_invoice_refused,
                         :num => invoice.number,
                         :company => invoice.company.name)
  end

  def invoice_paid(invoice,reason)
    I18n.locale = invoice.client.language
    @invoice = invoice
    @reason = reason
    if invoice.fetch_from_backup
      attachments[invoice.legal_filename] = invoice.legal_invoice
    end
    subject = I18n.t((invoice.type == "ReceivedInvoice" ?
                      :received_invoice_paid : :issued_invoice_paid),
                      :num => invoice.number, :company => invoice.company.name)
    mail :to => invoice.client.email,
      :from => Setting.mail_from,
      :subject => subject
  end

  # delayed_job hooks

  def self.failure(job)
    Event.create!(:name=>"error_#{event_name(job)}",
                  :invoice=>job.payload_object.args.first,
                  :info=>job.payload_object.args.last)
  end

  def self.success(job)
    Event.create!(:name=>"success_#{event_name(job)}",
                  :invoice=>job.payload_object.args.first,
                  :info=>job.payload_object.args.last)
  end

  def self.event_name(job)
    case job.payload_object.method_name
    when :received_invoice_accepted
      'accept_notification'
    when :received_invoice_refused
      'refuse_notification'
    else
      raise "unknown delayed_job method_name: #{job.payload_object.method_name}"
    end
  end

end
