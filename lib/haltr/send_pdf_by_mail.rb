# Signs a PDF invoice and sends it by email

module Haltr
  class SendPdfByMail < GenericSender

    attr_accessor :pdf

    def perform
      self.pdf = Haltr::Pdf.generate(invoice)
      HaltrMailer.send_invoice(invoice,{:pdf=>pdf}).deliver!
    rescue Net::SMTPFatalError => e
        EventError.create(
          :name    => "error_sending",
          :invoice => invoice,
          :notes   => e.message,
          :class_for_send => self.class.to_s.split('::').last.underscore
        )
      raise e
    end

    def success(job)
      filename = "#{I18n.t(:label_invoice)}_#{invoice.number.gsub(/[^\w]/,'_')}.pdf" rescue "Invoice.pdf"
      EventWithFile.create!(:name         => "success_sending",
                            :invoice      => invoice,
                            :notes        => invoice.recipient_emails.join(', '),
                            :file         => pdf,
                            :filename     => filename,
                            :content_type => 'application/pdf',
                            :class_for_send => 'send_signed_pdf_by_mail')
    end

  end
end
