class MailNotifier < ActionMailer::Base
  layout 'mail_notifier'
  helper :haltr
  unloadable

  def received_invoice_accepted(invoice,reason)
    @invoice = invoice
    @reason = reason
    mail :to => invoice.client.email,
      :from => Setting.mail_from,
      :subject => I18n.t(:received_invoice_accepted,
                         :num => invoice.number,
                         :company => invoice.company.name)
  end

  def received_invoice_refused(invoice,reason)
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
    @invoice = invoice
    @reason = reason
    if invoice.fetch_from_backup
      attachments[invoice.legal_filename] = invoice.legal_invoice
    end
    subject = I18n.t (invoice.type == "ReceivedInvoice" ?
                      :received_invoice_paid : :issued_invoice_paid),
        :num => invoice.number, :company => invoice.company.name
    mail :to => invoice.client.email,
      :from => Setting.mail_from,
      :subject => subject
  end

end
