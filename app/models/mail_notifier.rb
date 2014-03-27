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

  def received_invoice_paid(invoice,reason)
    I18n.locale = invoice.client.language
    @invoice = invoice
    @reason = reason
    if invoice.fetch_from_backup
      attachments[invoice.legal_filename] = invoice.legal_invoice
    end
    subject = I18n.t(:received_invoice_paid, :num => invoice.number,
                     :company => invoice.company.name)
    mail :to => invoice.client.email,
      :from => Setting.mail_from,
      :subject => subject
  end

  def issued_invoice_paid(invoice,reason)
    I18n.locale = invoice.client.language
    @invoice = invoice
    @reason = reason
    if invoice.fetch_from_backup
      attachments[invoice.legal_filename] = invoice.legal_invoice
    end
    subject = I18n.t(:issued_invoice_paid, :num => invoice.number,
                     :company => invoice.company.name)
    mail :to => invoice.client.email,
      :from => Setting.mail_from,
      :subject => subject
  end

  # delayed_job hooks

  def self.failure(job)
    EventWithMail.create!(:name=>"error_sending_notification_by_mail",
                          :invoice=>job.payload_object.args.first,
                          :notes=>job.payload_object.args.last)
  end

  def self.success(job)
    EventWithMail.create!(:name=>"success_sending_notification_by_mail",
                          :invoice=>job.payload_object.args.first,
                          :notes=>job.payload_object.args.last)
  end

end
