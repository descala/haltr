# Signs a PDF invoice and sends it by email

module Haltr
  class SendSignedPdfByMail < Struct.new(:invoice)

    def perform
      # create PDF
      pdf = Haltr::Pdf.generate(invoice)
      # sign PDF
      # TODO
      # send it by email
      HaltrMailer.send_invoice(invoice,pdf).deliver
    end

  end
end
