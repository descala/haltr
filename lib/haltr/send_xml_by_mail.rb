module Haltr
  class SendXmlByMail < GenericSender

    attr_accessor :format, :class_for_send

    def perform
      self.format ||= 'facturae32'
      self.xml    ||= Haltr::Xml.generate(invoice, format)
      self.class_for_send ||= 'send_xml_by_mail'
      if Redmine::Configuration['haltr_mailer_from']
        HaltrMailer.send_invoice(
          invoice,
          {:xml=>xml, :from=>Redmine::Configuration['haltr_mailer_from']}
        ).deliver!
      else
        HaltrMailer.send_invoice(invoice,{:xml=>xml}).deliver!
      end
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
      filename = "#{I18n.t(:label_invoice)}_#{invoice.number.gsub(/[^\w]/,'_')}.xml" rescue "Invoice.xml"
      EventWithFile.create!(:name         => "success_sending",
                            :invoice      => invoice,
                            :notes        => invoice.recipient_emails.join(', '),
                            :file         => xml,
                            :filename     => filename,
                            :content_type => 'application/xml',
                            :class_for_send => class_for_send)
    end

  end
end
