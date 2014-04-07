# Signs a PDF invoice and sends it by email

module Haltr
  class SendSignedPdfByMail <  GenericSender

    def perform
      # create PDF
      pdf = Haltr::Pdf.generate(invoice)
      # sign PDF
      # TODO
      # send it by email
      HaltrMailer.send_invoice(invoice,pdf).deliver
      #TODO: save sent pdf and allow to download it from Event link
    end

  end
end
