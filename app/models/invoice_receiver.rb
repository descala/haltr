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
      md5  = Digest::MD5.hexdigest(invoice.read)
      name = invoice.original_filename
      id   = name.gsub(/#{File.extname(name)}$/,'').split("_").last.to_i
      InvoiceReceiver.log "invoice #{name} has id #{id} has md5sum #{md5}"
      haltr_invoice = IssuedInvoice.find(id) if IssuedInvoice.exists?(id)
      if haltr_invoice.nil?
        InvoiceReceiver.log "Bounced invoice #{name} with id #{id} does not exist on haltr"
        return
      end
      if haltr_invoice.final_md5 != md5
        InvoiceReceiver.log "Bounced invoice #{name} with id #{id} does not match MD5 stored on haltr (received: #{md5} stored: #{haltr_invoice.final_md5})"
        return
      end
      Event.create(:name=>'bounced',:invoice=>haltr_invoice)
      InvoiceReceiver.log "Created event for invoice #{name} with id #{id}"
    end
  end

  class IncomingInvoice
    require "rexml/document"
    @@channels = {
      "facturae3.0" => "free_receive_facturae30",
      "facturae3.1" => "free_receive_facturae31",
      "facturae3.2" => "free_receive_facturae32",
      "ubl2.0"      => "free_receive_ubl20"
    }
    def self.process_file(invoice)
      doc = REXML::Document.new(invoice.read.chomp)
      facturae_version = REXML::XPath.first(doc,"//FileHeader/SchemaVersion")
      ubl_version = REXML::XPath.first(doc,"//Invoice/*:UBLVersionID")
      xpaths = {}
      channel=""
      if facturae_version
        invoice_format="facturae#{facturae_version.text}"
        InvoiceReceiver.log "Incoming invoice is FacturaE #{facturae_version.text}"
        xpaths[:invoice_number]          = [ "//Invoices/Invoice/InvoiceHeader/InvoiceNumber",
                                             "//Invoices/Invoice/InvoiceHeader/InvoiceSeriesCode" ]
        xpaths[:invoice_date]            = "//Invoices/Invoice/InvoiceIssueData/IssueDate"
        xpaths[:invoice_import]          = "//Invoices/Invoice/InvoiceTotals/InvoiceTotal"
        xpaths[:invoice_tax_percent]     = "//Invoices/Invoice/InvoiceTotals/TotalTaxOutputs"
        xpaths[:invoice_subtotal]        = "//Invoices/Invoice/InvoiceTotals/TotalGrossAmountBeforeTaxes"
        xpaths[:invoice_withholding_tax] = "//Invoices/Invoice/InvoiceTotals/TotalTaxesWithheld"
        xpaths[:invoice_due_date]        = "//Invoices/Invoice/PaymentDetails/Installment/InstallmentDueDate"
        xpaths[:seller_taxcode]          = "//Parties/SellerParty/TaxIdentification/TaxIdentificationNumber"
        xpaths[:seller_name]             = "//Parties/SellerParty/LegalEntity/CorporateName"
        xpaths[:seller_name2]            = [ "//Parties/SellerParty/Individual/Name",
                                             "//Parties/SellerParty/Individual/FirstSurname",
                                             "//Parties/SellerParty/Individual/SecondSurname" ]
        xpaths[:seller_address]          = "//Parties/SellerParty/*/*/Address"
        xpaths[:seller_province]         = "//Parties/SellerParty/*/*/Province"
        xpaths[:seller_countrycode]      = "//Parties/SellerParty/*/*/CountryCode"
        xpaths[:seller_website]          = "//Parties/SellerParty/*/ContactDetails/WebAddress"
        xpaths[:seller_email]            = "//Parties/SellerParty/*/ContactDetails/ElectronicMail"
        xpaths[:seller_cp_city]          = [ "//Parties/SellerParty/*/*/PostCode",
                                             "//Parties/SellerParty/*/*/Town" ]
        xpaths[:seller_cp_city2]         = "//Parties/SellerParty/*/*/PostCodeAndTown"
        xpaths[:buyer_taxcode]           = "//Parties/BuyerParty/TaxIdentification/TaxIdentificationNumber"
        xpaths[:currency]                = "//FileHeader/Batch/InvoiceCurrencyCode"

        ch_name = @@channels[invoice_format]
        if ch_name
          channel="/var/spool/b2brouter/input/#{ch_name}"
        end
      elsif ubl_version
        invoice_format="ubl#{ubl_version.text}"
        InvoiceReceiver.log "Incoming invoice is UBL #{facturae_version.text}"
        xpaths[:invoice_number]          = ""
        xpaths[:invoice_date]            = ""
        xpaths[:invoice_import]          = ""
        xpaths[:invoice_tax_percent]     = ""
        xpaths[:invoice_subtotal]        = ""
        xpaths[:invoice_withholding_tax] = ""
        xpaths[:invoice_due_date]        = ""
        xpaths[:seller_taxcode]          = ""
        xpaths[:seller_name]             = ""
        xpaths[:seller_name2]            = nil
        xpaths[:seller_address]          = ""
        xpaths[:seller_province]         = ""
        xpaths[:seller_countrycode]      = ""
        xpaths[:seller_website]          = ""
        xpaths[:seller_email]            = ""
        xpaths[:seller_cp_city]          = ""
        xpaths[:seller_cp_city2]         = nil
        xpaths[:buyer_taxcode]           = ""
        xpaths[:currency]                = ""
        ch_name = @@channels[invoice_format]
        if ch_name
          channel="/var/spool/b2brouter/input/#{ch_name}"
        end
      else
        InvoiceReceiver.log "Incoming invoice with unknown format"
        #TODO: bounce message
      end
      ri = invoice_from_xml(doc,xpaths)
      ri.invoice_format = invoice_format
      invoice.rewind
      ri.md5 = Digest::MD5.hexdigest(invoice.read)
      ri.save!
      if File.directory? channel
        i=2
        extension = File.extname(invoice.original_filename)
        base = invoice.original_filename.gsub(/#{extension}$/,'')
        destination = "#{channel}/#{base}_#{ri.id}#{extension}"
        while File.exist? destination do
          destination = "#{channel}/#{base}_#{i}_#{ri.id}#{extension}"
          i+=1
        end
        invoice.rewind
        open(destination,'w') {|f| f.puts invoice.read.chomp }
        InvoiceReceiver.log "Sent invoice to validation channel: #{destination}"
      else
        InvoiceReceiver.log "Invoice format without validation channel #{channel}"
      end
    rescue Exception => e
      InvoiceReceiver.log e.message
    end

    def self.invoice_from_xml(doc,xpaths)
      buyer_taxcode  = get_xpath(doc,xpaths[:buyer_taxcode])
      company = Company.find_by_taxcode(buyer_taxcode)
      raise "Company with taxcode '#{buyer_taxcode}' not found" unless company #TODO: bounce message

      seller_taxcode = get_xpath(doc,xpaths[:seller_taxcode])
      client         = company.project.clients.find_by_taxcode(seller_taxcode)
      currency       = get_xpath(doc,xpaths[:currency])
      unless client
        seller_name           = get_xpath(doc,xpaths[:seller_name]) || get_xpath(doc,xpaths[:seller_name2])
        seller_address        = get_xpath(doc,xpaths[:seller_address])
        seller_province       = get_xpath(doc,xpaths[:seller_province])
        seller_countrycode    = get_xpath(doc,xpaths[:seller_countrycode])
        seller_website        = get_xpath(doc,xpaths[:seller_website])
        seller_email          = get_xpath(doc,xpaths[:seller_email])
        seller_cp_city        = get_xpath(doc,xpaths[:seller_cp_city]) || get_xpath(doc,xpaths[:seller_cp_city2])
        seller_postalcode = seller_cp_city.split(" ").first
        seller_city       = seller_cp_city.gsub(/^#{seller_postalcode} /,'')

        client = Client.new(:taxcode        => seller_taxcode,
                            :name           => seller_name,
                            :address        => seller_address,
                            :province       => seller_province,
                            :country        => seller_countrycode,
                            :website        => seller_website,
                            :email          => seller_email,
                            :postalcode     => seller_postalcode,
                            :city           => seller_city,
                            :currency       => currency,
                            :project        => company.project)
        client.save!
      end
      invoice_number      = get_xpath(doc,xpaths[:invoice_number])
      invoice_date        = get_xpath(doc,xpaths[:invoice_date])
      invoice_import      = get_xpath(doc,xpaths[:invoice_import])
      invoice_tax_percent = get_xpath(doc,xpaths[:invoice_tax_percent])
      invoice_subtotal    = get_xpath(doc,xpaths[:invoice_subtotal])
      invoice_withholding_tax = get_xpath(doc,xpaths[:invoice_withholding_tax])
      invoice_due_date    = get_xpath(doc,xpaths[:invoice_due_date])

      r = ReceivedInvoice.new(:number      => invoice_number,
                          :client          => client,
                          :date            => invoice_date,
                          :import          => invoice_import.to_money,
                          :currency        => currency,
                          :tax_percent     => invoice_tax_percent,
                          :subtotal        => invoice_subtotal.to_money,
                          :withholding_tax => invoice_withholding_tax.to_money,
                          :due_date        => invoice_due_date,
                          :project         => company.project)
      return r
    end

    # retrieve xpath from document
    # if xpath is an array, concatenates its values
    def self.get_xpath(doc,xpath)
      val=""
      if xpath.is_a?(Array)
        xpath.each do |xp|
          txt = REXML::XPath.first(doc,xp).text rescue ""
          unless txt.blank?
            val += txt
            val += " " unless xp == xpath.last
          end
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
