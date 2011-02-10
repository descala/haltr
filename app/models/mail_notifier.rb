class MailNotifier < ActionMailer::Base

  unloadable

  def received_invoice_accepted(invoice,reason)
    recipients invoice.client.email
    from 'noreply@b2brouter.net'
    subject I18n.t(:received_invoice_accepted, :num => invoice.number, :company => invoice.client.project.company.name)
    body :invoice => invoice, :reason => reason
    content_type "text/plain"
    body render(:file => "received_invoice_accepted.rhtml", :body => body, :layout => 'mail_notifier.erb')
  end

  def received_invoice_refused(invoice,reason)
    recipients invoice.client.email
    from 'noreply@b2brouter.net'
    subject I18n.t(:received_invoice_refused, :num => invoice.number, :company => invoice.client.project.company.name)
    body :invoice => invoice, :reason => reason
    content_type "text/plain"
    body render(:file => "received_invoice_refused.rhtml", :body => body, :layout => 'mail_notifier.erb')
    if invoice.fetch_legal_by_http
      attachment :content_type => invoice.legal_content_type,
          :filename => invoice.legal_filename,
          :body => invoice.legal_invoice
    end
  end

end
