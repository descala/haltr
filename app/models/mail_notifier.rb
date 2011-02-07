class MailNotifier < ActionMailer::Base

  unloadable

  def received_invoice_accepted(invoice)
    recipients invoice.client.email
    from 'noreply@b2brouter.net'
    subject I18n.t(:received_invoice_accepted, :num => invoice.number, :company => invoice.client.project.company.name)
    body :invoice => invoice
    content_type "text/plain"
    body render(:file => "received_invoice_accepted.rhtml", :body => body, :layout => 'mail_notifier.erb')
  end

  def received_invoice_refused(invoice)
    recipients invoice.client.email
    from 'noreply@b2brouter.net'
    subject I18n.t(:received_invoice_refused, :num => invoice.number, :company => invoice.client.project.company.name)
    body :invoice => invoice
    content_type "text/plain"
    body render(:file => "received_invoice_refused.rhtml", :body => body, :layout => 'mail_notifier.erb')
  end

end
