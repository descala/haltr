class InvoiceMailer < ActionMailer::Base

  include Redmine::I18n

  def issued_invoice_mail(invoice,options={})

    pdf_file_path = options[:pdf_file_path]

    recipients invoice.uniq_emails.join(', ')
    from options[:from] || "#{invoice.company.name} <#{invoice.company.email}>"
    bcc options[:from] || invoice.company.email
    subject "#{l(:label_invoice)} #{invoice.number} (#{invoice.company.name})"
    sent_on Time.now
    headers 'X-Haltr-Id' => invoice.id

    part "text/plain" do |p|
      p.body = render_message("issued_invoice_mail.text.plain.erb", :invoice => invoice)
    end

    attachment :content_type => "application/pdf",
      :filename => invoice.pdf_name,
      :body => File.read(pdf_file_path)
  end

end
