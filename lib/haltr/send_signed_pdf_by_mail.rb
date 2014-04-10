# Signs a PDF invoice and sends it by email
module Haltr
  class SendSignedPdfByMail < GenericSender

    attr_accessor :pdf

    def perform
      self.pdf = Haltr::Pdf.generate(invoice)
      #TODO: sign PDF
      HaltrMailer.send_invoice(invoice,{:pdf=>pdf}).deliver
    end

    def create_event(name)
      filename = "#{I18n.t(:label_invoice)}_#{invoice.number.gsub(/[^\w]/,'_')}.pdf" rescue "Invoice.pdf"
      EventWithFile.create!(:name         => name,
                            :invoice      => invoice,
                            :notes        => invoice.recipient_emails.join(', '),
                            :file         => pdf,
                            :filename     => filename,
                            :content_type => 'application/pdf',
                            :class_for_send => 'send_signed_pdf_by_mail')
    end

  end
end
