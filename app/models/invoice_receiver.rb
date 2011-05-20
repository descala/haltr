# Receives an email extract its attachments and determines if it is a bounced
# mail for a sent invoice, or an incoming invoice.
#
# Assuming that mail is a file with raw email message,
# you can test it from command line with:
# script/runner 'InvoiceReceiver.receive(`cat mail`)'
#
class InvoiceReceiver < ActionMailer::Base
  unloadable

  def receive(email)
    return unless email.multipart? # email has no attachments
    invoices = attached_invoices(email)

    # bounced invoice
    if is_bounce?(email)
      if invoices.size == 1 # we send only 1 invoice on each mail
        InvoiceReceiver.log "Bounced invoice mail received (#{invoices.first.original_filename})"
        IncomingBouncedInvoice.process_file(invoices.first)
      else
        InvoiceReceiver.log "Discarding bounce mail with != 1 (#{invoices.size}) invoices attached (#{invoices.collect {|i| i.original_filename}.join(',')})"
      end

    # incoming invoices (PDF/XML)
    else
      InvoiceReceiver.log "Incoming invoice mail with #{invoices.size} attached invoices"
      company = Company.find_by_taxcode(email['to'].to_s.scan(/[\w.]+@[\w.]+/).first.split("@").first)
      from = email['from'].to_s.scan(/[\w.]+@[\w.]+/).first
      if company
        invoices.each do |invoice|
          if invoice.content_type == "application/xml"
            IncomingXmlInvoice.process_file(invoice,company,"email",from)
          elsif invoice.content_type == "application/pdf"
            IncomingPdfInvoice.process_file(invoice,company,"email",from)
          else
            InvoiceReceiver.log "Discarding #{invoice.original_filename} on incoming mail (#{invoice.content_type})"
          end
        end
      else
        InvoiceReceiver.log "Discarding email for #{email['to'].to_s} (Can't find company with taxcode #{email['to'].to_s.split("@").first})"
      end
    end
  end

  def self.log(message,level="info")
    RAILS_DEFAULT_LOGGER.send(level,message)
    puts message
  end

  private

  def attached_invoices(email)
    invoices = []
    email.attachments.each do |attachment|
      invoices << attachment if attachment.content_type == "application/xml" || attachment.content_type == "application/pdf"
    end
    email.parts.each do |part|
      attached_mail = nil
      attached_mail = TMail::Mail.parse(part.body) if email.attachment?(part) rescue nil
      next if attached_mail.nil? || attached_mail.attachments.nil?
      attached_mail.attachments.each do |attachment|
        invoices << attachment if attachment.content_type == "application/xml" || attachment.content_type == "application/pdf"
      end
    end
    invoices
  end

  def is_bounce?(email)
    email.to.include? "noreply@b2brouter.net"
  end

end
