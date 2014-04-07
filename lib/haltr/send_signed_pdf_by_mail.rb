# Signs a PDF invoice and sends it by email

module Haltr
  class SendSignedPdfByMail < Struct.new(:invoice, :user)

    attr_accessor :pdf

    def perform
      # create PDF
      self.pdf = Haltr::Pdf.generate(invoice)
      # sign PDF
      # TODO
      # send it by email
      HaltrMailer.send_invoice(invoice,pdf).deliver
      #TODO: save sent pdf and allow to download it from Event link
    end

    # delayed_job hooks

    def failure(job)
      create_event("error_sending")
    end

    def success(job)
      create_event("success_sending")
    end

    private

    def create_event(name)
      filename = "#{I18n.t(:label_invoice)}_#{invoice.number.gsub(/[^\w]/,'_')}.pdf" rescue "Invoice.pdf"
      EventWithFile.create!(:name         => name,
                            :invoice      => invoice,
                            :user         => user,
                            :notes        => invoice.client.email,
                            :file         => pdf,
                            :filename     => filename,
                            :content_type => 'application/pdf')
    end

  end
end
