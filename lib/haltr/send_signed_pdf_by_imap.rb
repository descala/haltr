# Stores an email with the invoice attached as draft on IMAP server.
module Haltr
  class SendSignedPdfByImap < GenericSender

    attr_accessor :pdf
    require 'net/imap'

    def perform
      self.pdf = Haltr::Pdf.generate(invoice)
      #TODO: sign PDF
      IMAP.send_invoice(invoice,pdf)
    end

    def create_event(name)
      filename = "#{I18n.t(:label_invoice)}_#{invoice.number.gsub(/[^\w]/,'_')}.pdf" rescue "Invoice.pdf"
      EventWithFile.create!(:name         => name,
                            :invoice      => invoice,
                            :notes        => invoice.recipient_emails.join(', '),
                            :file         => pdf,
                            :filename     => filename,
                            :content_type => 'application/pdf')
    end

    # IMAP options configured on company:
    #  host      IMAP server host (default: 127.0.0.1)
    #  port      IMAP server port (default: 143)
    #  ssl       Use SSL? (default: false)
    #  username  IMAP account
    #  password  IMAP password
    #  folder    IMAP folder to read (default: INBOX) (TODO)
    def create_imap_draft
      company = invoice.company
      message = InvoiceMailer.issued_invoice_mail(invoice, { :pdf=>pdf,
                                                             :from => company.imap_from })
      if Rails.env != 'test'
        host   = company.imap_host || '127.0.0.1'
        port   = company.imap_port || '143'
        ssl    = company.imap_ssl
        folder = 'INBOX/Drafts' #TODO allow to change this
        imap   = Net::IMAP.new(host, port, ssl)
        imap.login(company.imap_username, company.imap_password) unless company.imap_username.nil?
        imap.append(folder, message.to_s.gsub(/\n/, "\r\n"), [:Draft], Time.now)
      end
      invoice.manual_send
      return message
    end

  end
end
