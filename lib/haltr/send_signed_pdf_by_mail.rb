# Signs a PDF invoice and sends it by email

module Haltr
  class SendSignedPdfByMail < Struct.new(:invoice, :user)

    def perform
      # create PDF
      pdf = Haltr::Pdf.generate(invoice)
      # sign PDF
      # TODO
      # send it by email
      HaltrMailer.send_invoice(invoice,pdf).deliver
      #TODO: save sent pdf and allow to download it from Event link
    end

    # delayed_job hooks

    def failure(job)
      Event.create!(:name    => "error_sending",
                    :invoice => invoice,
                    :user    => user,
                    :notes   => invoice.client.email)
    end

    def success(job)
      Event.create!(:name    => "success_sending",
                    :invoice => invoice,
                    :user    => user,
                    :notes   => invoice.client.email)
    end

  end
end
