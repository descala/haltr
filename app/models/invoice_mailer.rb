class InvoiceMailer < ActionMailer::Base

  unloadable
  include Redmine::I18n

  def issued_invoice_mail(invoice,options={})

    @invoice = invoice
    pdf_file_path = options[:pdf_file_path]
    recipients = invoice.recipient_emails.join(', ')
    from = options[:from] || "#{invoice.company.name} <#{invoice.company.email}>"
    bcc = options[:from] || invoice.company.email
    subject = "#{l(:label_invoice)} #{invoice.number} (#{invoice.company.name})"

    headers['X-Haltr-Id'] = invoice.id

    if pdf_file_path
      attachments[invoice.pdf_name] = File.read(pdf_file_path)
    end

    mail :to => recipients,
      :from => from,
      :bcc => bcc,
      :subject => subject

  end

end
