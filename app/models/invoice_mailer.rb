# TODO is this the same as HaltrMailer?

class InvoiceMailer < ActionMailer::Base

  unloadable
  include Redmine::I18n


  def issued_invoice_mail(invoice,options={})

    @invoice = invoice
    pdf = options[:pdf]
    recipients = invoice.recipient_emails.join(', ')
    from = options[:from] || "#{invoice.company.name.gsub(',','')} <#{invoice.company.email}>"
    bcc = options[:from] || invoice.company.email
    subject = "#{l(:label_invoice)} #{invoice.number} (#{invoice.company.name})"

    headers['X-Haltr-Id'] = invoice.id

    attachments[invoice.pdf_name] = pdf if pdf

    mail :to => recipients,
      :from => from,
      :bcc => bcc,
      :subject => subject

  end

end
