# Receives an email extract its attachments and determines if it is a bounced
# mail for a sent invoice, or an incoming invoice.
#
# Assuming that mail is a file with raw email message,
# you can test it from command line with:
# script/runner 'InvoiceReceiver.receive(`cat mail`)'
#
class InvoiceReceiver < ActionMailer::Base
  unloadable
  @@logger = RAILS_DEFAULT_LOGGER

  class BouncedInvoice
    @@logger = RAILS_DEFAULT_LOGGER
    def self.process_file(invoice)
      md5  = Digest::MD5.hexdigest(invoice.read)
      name = invoice.original_filename
      id   = name.gsub(/#{File.extname(name)}$/,'').split("_").last.to_i
      @@logger.info "invoice #{name} has id #{id} has md5sum #{md5}"
      invoice = InvoiceDocument.find_by_number(id)# if InvoiceDocument.exists?(id)
      if invoice.nil?
        @@logger.info "Bounced invoice #{name} with id #{id} does not exist on haltr"
        return
      end
      if invoice.md5 != md5
        @@logger.info "Bounced invoice #{name} with id #{id} does not match MD5 stored on haltr (received: #{md5} stored: #{invoice.md5})"
        return
      end
      Event.create(:name=>'bounced',:invoice=>invoice)
    end
  end

  class IncomingInvoice
    @@logger = RAILS_DEFAULT_LOGGER
    def self.process_file(invoice)
      #TODO:
      # comprovar format de la factura, crear bounce si no es suportat
      # id = crear InvoiceIn amb (num fra, nif i nom emisor, nif i nom receptor, data fra, import total), agafant els camps de l'XPATH que toqui segons format
      # enviar a un canal (segons format) b2brouter amb nom CIF_id.xml
      # canal:
      #   -validar format
      #   -crear Event a haltr (firma ok/error)
      #   -validar firma
      #   -crear Event a haltr (format ok/error)
      #   -fer backup per poder descarregar
    end
  end

  def receive(email)
    return unless email.multipart? # email has no attachments
    invoices = attached_invoices(email)

    # bounced invoice
    if is_bounce?(email)
      if invoices.size == 1 # we send only 1 invoice on each mail
        @@logger.info "Bounced invoice mail"
        BouncedInvoice.process_file(invoices.first)
      else
        @@logger.info "Discarding bounce mail with >1 invoices attached (#{invoices.collect {|i| i.original_filename}.join(',')})"
      end

    # incoming invoices
    else
      @@logger.info "Incoming invoice mail"
      invoices.each do |invoice|
        IncomingInvoice.process_file(invoice)
      end
    end
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
        invoices << attachment if attachment.content_type == "application/xml"
      end
    end
    invoices
  end

  def is_bounce?(email)
    email.to.include? "noreply@b2brouter.net"
  end

end
