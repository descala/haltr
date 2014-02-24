# Stores an email with the invoice attached as draft on IMAP server.
#
# IMAP options configured on company:
#  host      IMAP server host (default: 127.0.0.1)
#  port      IMAP server port (default: 143)
#  ssl       Use SSL? (default: false)
#  username  IMAP account
#  password  IMAP password
#  folder    IMAP folder to read (default: INBOX) (TODO)

require 'net/imap'

module Haltr
  module IMAP

      unloadable

      def self.send_invoice(invoice, path)
        company = invoice.company
        message = InvoiceMailer.issued_invoice_mail(invoice,
                                                    {:pdf_file_path=>path,
                                                     :from => company.imap_from})
        host   = company.imap_host || '127.0.0.1'
        port   = company.imap_port || '143'
        ssl    = company.imap_ssl
        folder = 'INBOX/Drafts' #TODO allow to change this
        imap   = Net::IMAP.new(host, port, ssl)

        imap.login(company.imap_username, company.imap_password) unless company.imap_username.nil?
        imap.append(folder, message.to_s.gsub(/\n/, "\r\n"), [:Draft], Time.now)
        invoice.manual_send
      end

      private

      def self.logger
        Rails.logger
      end

  end
end
