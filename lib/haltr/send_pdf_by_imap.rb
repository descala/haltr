# Stores an email with the invoice attached as draft on IMAP server.

module Haltr
  class SendPdfByIMAP < GenericSender

    require 'net/imap'

    include RenderAnywhere

    attr_accessor :invoice, :pdf

    def initialize(invoice, user=nil)
      self.invoice = invoice
    end

    def immediate_perform(doc)
      self.pdf = doc
      create_imap_draft
      EventWithFile.create!(:name         => "success_sending",
                            :invoice      => invoice,
                            :notes        => invoice.recipient_emails.join(', '),
                            :file         => pdf,
                            :filename     => filename,
                            :content_type => 'application/pdf',
                            :class_for_send => 'send_pdf_by_imap')
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
      if Rails.env != 'test'
        host   = company.imap_host || '127.0.0.1'
        port   = company.imap_port || '143'
        ssl    = company.imap_ssl
        imap   = Net::IMAP.new(host, port, ssl)
        imap.login(company.imap_username, company.imap_password) unless company.imap_username.nil?
        if imap.list('','INBOX/Drafts')
          folder = 'INBOX/Drafts'
        elsif imap.list('','Drafts')
          folder = 'Drafts'
        else
          folder = 'Drafts'
          imap.create(folder)
        end
        imap.append(folder, mail_message.to_s.gsub(/\n/, "\r\n"), [:Draft], Time.now)
      end
    end

    def mail_message
      if invoice.is_a?(Quote)
        subj = invoice.company.quote_mail_subject(invoice.client.language, invoice)
        body = invoice.company.quote_mail_body(invoice.client.language, invoice)
      else
        subj = invoice.company.invoice_mail_subject(invoice.client.language, invoice)
        body = invoice.company.invoice_mail_body(invoice.client.language, invoice)
      end

      Rails.application.routes.default_url_options = { host: Setting.host_name, protocol: Setting.protocol }

      body_txt = render(
        template: "haltr_mailer/send_invoice.text.erb",
        layout:   nil,
        locals:   { :@invoice => invoice, :@body => body }
      )

      mail = Mail.new
      mail.charset   = "UTF-8"
      mail.to        = invoice.recipient_emails.join(', ')
      mail.bcc       = invoice.company.email
      mail.from      = "#{invoice.company.name.gsub(',','')} <#{invoice.company.email}>"
      mail.subject   = subj
      mail.text_part do
        body body_txt
      end

      # pdf
      mail.add_file(filename: filename, content: pdf)

      # other invoice attachments
      invoice.attachments.each do |attachment|
        mail.add_file(filename: "attachment_#{attachment.filename}", content: File.read(attachment.diskfile)) rescue nil
      end

      mail
    end

    def filename
      "#{I18n.t(:label_invoice)}_#{invoice.number.gsub(/[^\w]/,'_')}.pdf" rescue "Invoice.pdf"
    end
  end
end
