module Haltr
  class SendSignedPdfByIMAP < GenericSender

    def perform
      pdf = Haltr::Pdf.generate(invoice)
      IMAP.send_invoice(invoice,pdf)
    end

  end
end
