# Receives an email extract its attachments and determines if it is a bounced
# mail for a sent invoice, or an incoming invoice.
#
# Assuming that mail is a file with raw email message,
# you can test it from command line with:
# script/runner 'InvoiceReceiver.receive(`cat mail`)'
#
class InvoiceReceiver < ActionMailer::Base
  unloadable

  class BouncedInvoice
    def self.process_file(invoice)
      md5  = Digest::MD5.hexdigest(invoice.read.chomp)
      name = invoice.original_filename
      id   = name.gsub(/#{File.extname(name)}$/,'').split("_").last.to_i
      InvoiceReceiver.log "invoice #{name} has id #{id} has md5sum #{md5}"
      haltr_invoice = IssuedInvoice.find(id) if IssuedInvoice.exists?(id)
      if haltr_invoice.nil?
        InvoiceReceiver.log "Bounced invoice #{name} with id #{id} does not exist on haltr"
        return
      end
      if haltr_invoice.md5 != md5
        InvoiceReceiver.log "Bounced invoice #{name} with id #{id} does not match MD5 stored on haltr (received: #{md5} stored: #{haltr_invoice.md5})"
        return
      end
      Event.create(:name=>'bounced',:invoice=>haltr_invoice)
      InvoiceReceiver.log "Created event for invoice #{name} with id #{id}"
    end
  end

  class IncomingInvoice
    require "rexml/document"
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
      doc = REXML::Document.new(invoice.read.chomp)
      facturae_version = REXML::XPath.first(doc,"//FileHeader/SchemaVersion")
      ubl_version = REXML::XPath.first(doc,"//Invoice/*:UBLVersionID")
      xpaths = {}
      if facturae_version
        InvoiceReceiver.log "Incoming invoice is FacturaE #{facturae_version.text}"
        xpaths[:invoice_number] = [ "//Invoices/Invoice/InvoiceHeader/InvoiceNumber",
                                    "//Invoices/Invoice/InvoiceHeader/InvoiceSeriesCode" ]
        xpaths[:seller_taxcode] = "//Parties/SellerParty/TaxIdentification/TaxIdentificationNumber"
        xpaths[:seller_name]    = "//Parties/SellerParty/LegalEntity/CorporateName"
        xpaths[:seller_name2]   = [ "//Parties/SellerParty/Individual/Name",
                                    "//Parties/SellerParty/Individual/FirstSurname",
                                    "//Parties/SellerParty/Individual/SecondSurname" ]
        xpaths[:buyer_taxcode]  = "//Parties/BuyerParty/TaxIdentification/TaxIdentificationNumber"
#        xpaths[:buyer_name]     = "//Parties/BuyerParty/LegalEntity/CorporateName"
        xpaths[:buyer_name2]    = [ "//Parties/BuyerParty/Individual/Name",
                                    "//Parties/BuyerParty/Individual/FirstSurname",
                                    "//Parties/BuyerParty/Individual/SecondSurname" ]
        xpaths[:invoice_date]   = "//Invoices/Invoice/InvoiceIssueData/IssueDate"
        xpaths[:invoice_import] = "//Invoices/Invoice/InvoiceTotals/InvoiceTotal"
        xpaths[:currency]       = "//FileHeader/Batch/InvoiceCurrencyCode"
      elsif ubl_version
        InvoiceReceiver.log "Incoming invoice is UBL #{facturae_version.text}"
        xpaths[:invoice_number] = ""
        xpaths[:seller_taxcode] = ""
        xpaths[:seller_name]    = ""
        xpaths[:seller_name2]   = nil
        xpaths[:buyer_taxcode]  = ""
#        xpaths[:buyer_name]     = ""
        xpaths[:buyer_name2]    = nil
        xpaths[:invoice_date]   = ""
        xpaths[:invoice_import] = ""
        xpaths[:currency] = ""
      else
        InvoiceReceiver.log "Incoming invoice with unknown format"
        #TODO: bounce message
      end
      ri = invoice_from_xml(doc,xpaths)
      ri.save!
    rescue Exception => e
      InvoiceReceiver.log e.message
    end

    def self.invoice_from_xml(doc,xpaths)
      invoice_number = get_xpath(doc,xpaths[:invoice_number])
      seller_taxcode = get_xpath(doc,xpaths[:seller_taxcode])
      seller_name    = get_xpath(doc,xpaths[:seller_name]) || get_xpath(doc,xpaths[:seller_name2])
      buyer_taxcode  = get_xpath(doc,xpaths[:buyer_taxcode])
#      buyer_name     = get_xpath(doc,xpaths[:buyer_name]) || get_xpath(doc,xpaths[:buyer_name2])
      invoice_date   = get_xpath(doc,xpaths[:invoice_date])
      invoice_import = get_xpath(doc,xpaths[:invoice_import])
      currency       = get_xpath(doc,xpaths[:currency])
      company = Company.find_by_taxcode(buyer_taxcode)
      raise "Company with taxcode '#{buyer_taxcode}' not found" unless company #TODO: bounce message
      client = company.project.clients.find_by_taxcode(seller_taxcode)
      unless client
        client = Client.new(:taxcode=>seller_taxcode,:name=>seller_name,:currency=>currency,:project=>company.project)
        client.save!
      end
      r = ReceivedInvoice.new(:number=>invoice_number,
                          :client=>client,
                          :date=>invoice_date,
                          :import=>invoice_import.to_money,
                          :currency=>currency)
      return r
    end

    # retrieve xpath from document
    # if xpath is an array, concatenates its values
    def self.get_xpath(doc,xpath)
      val=""
      if xpath.is_a?(Array)
        xpath.each do |xp|
          val += REXML::XPath.first(doc,xp).text rescue ""
        end
      elsif xpath.nil?
        nil
      else
        val += REXML::XPath.first(doc,xpath).text rescue ""
      end
      val.blank? ? nil : val
    end
  end

  def receive(email)
    return unless email.multipart? # email has no attachments
    invoices = attached_invoices(email)

    # bounced invoice
    if is_bounce?(email)
      if invoices.size == 1 # we send only 1 invoice on each mail
        InvoiceReceiver.log "Bounced invoice mail received (#{invoices.first.original_filename})"
        BouncedInvoice.process_file(invoices.first)
      else
        InvoiceReceiver.log "Discarding bounce mail with > 1 (#{invoices.size}) invoices attached (#{invoices.collect {|i| i.original_filename}.join(',')})"
      end

    # incoming invoices
    else
      InvoiceReceiver.log "Incoming invoice mail with #{invoices.size} attached invoices"
      invoices.each do |invoice|
        if invoice.content_type == "application/xml"
          IncomingInvoice.process_file(invoice)
        else
          InvoiceReceiver.log "Discarding #{invoice.original_filename} on incoming mail (#{invoice.content_type})"
        end
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
        invoices << attachment if attachment.content_type == "application/xml"
      end
    end
    invoices
  end

  def is_bounce?(email)
    email.to.include? "noreply@b2brouter.net"
  end

end
