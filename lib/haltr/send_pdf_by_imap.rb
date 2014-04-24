# Stores an email with the invoice attached as draft on IMAP server.

module Haltr
  class SendPdfByIMAP < GenericSender

    attr_accessor :pdf
    require 'net/imap'

    def perform
      self.pdf = Haltr::Pdf.generate(invoice)
      create_imap_draft
    end

    def success(job)
      filename = "#{I18n.t(:label_invoice)}_#{invoice.number.gsub(/[^\w]/,'_')}.pdf" rescue "Invoice.pdf"
      EventWithFile.create!(:name         => "success_sending",
                            :invoice      => invoice,
                            :notes        => invoice.recipient_emails.join(', '),
                            :file         => pdf,
                            :filename     => filename,
                            :content_type => 'application/pdf',
                            :class_for_send => 'send_signed_pdf_by_imap')
    end

    # IMAP options configured on company
    #  host      IMAP server host (default: 127.0.0.1)
    #  port      IMAP server port (default: 143)
    #  ssl       Use SSL? (default: false)
    #  username  IMAP account
    #  password  IMAP password
    #  folder    IMAP folder to read (default: INBOX) (TODO)
    def create_imap_draft
      company = invoice.company
      message = HaltrMailer.send_invoice(invoice, {:pdf=>pdf, :from => company.imap_from})
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
