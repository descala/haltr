# Receives an email extract its attachments and determines if it is a bounced
# mail for a sent invoice, or an incoming invoice.
#
# Assuming that mail is a file with raw email message,
# you can test it from command line with:
#
#  bundle exec rails runner -e development "InvoiceReceiver.receive(File.read('/path/to/mail'))"
#
class HaltrMailHandler < MailHandler # < ActionMailer::Base
  unloadable

  def receive(email)
    invoices = []
    if email.multipart?
      raw_invoices = attached_invoices(email)

      if email.to and email.to.include? "noreply@b2brouter.net"
        # bounced invoice
        if raw_invoices.size == 1 # we send only 1 invoice on each mail
          logger.info "Bounced invoice mail received (#{raw_invoices.first.filename})"
          process_bounced_file(raw_invoices.first)
        else
          logger.info "Discarding bounce mail with != 1 (#{raw_invoices.size}) invoices attached (#{raw_invoices.collect {|i| i.filename}.join(',')})"
        end
      else
        # incoming invoices (PDF/XML)
        logger.info "Incoming invoice mail with #{raw_invoices.size} attached invoices"
        company_found=false
        email['to'].to_s.scan(/[\w.]+@[\w.]+/).each do |to|
          company = Company.find_by_taxcode(to.split("@").first)
          if company
            from = email['from'].to_s.scan(/[\w.]+@[\w.]+/).first
            company_found=true
            raw_invoices.each do |raw_invoice|

              # discard invoice if md5 exists
              tmpfile = Tempfile.new("invoice.xml", :encoding => 'ascii-8bit')
              tmpfile.write(raw_invoice.read.chomp)
              tmpfile.close
              md5 = `md5sum #{tmpfile.path} | cut -d" " -f1`.chomp
              if found_invoice = Invoice.find_by_md5(md5)
                invoices << found_invoice
                logger.error "Discarding repeated invoice with md5 #{md5}. Invoice.id = #{found_invoice.id}"
              else
                if raw_invoice.content_type =~ /xml/
                  invoices << process_xml_file(raw_invoice,company,from,md5)
                elsif raw_invoice.content_type =~ /pdf/
                  invoices << process_pdf_file(raw_invoice,company,from,md5)
                else
                  logger.info "Discarding #{raw_invoice.filename} on incoming mail (#{raw_invoice.content_type})"
                end
              end
            end
            break #TODO: allow incoming invoice to several companies?
          end
        end
        unless company_found
          logger.info "Discarding email for #{email['to'].to_s} (Can't find company with taxcode #{email['to'].to_s.split("@").first})"
        end
      end
    else
      # we do not process emails without attachments
      logger.info "email has no attachments"
    end
    return invoices
  end

  require "rexml/document"
  require "tempfile"

  @@channels = {
    "facturae3.0" => "free_receive_facturae30",
    "facturae3.1" => "free_receive_facturae31",
    "facturae3.2" => "free_receive_facturae32",
    "ubl2.0"      => "free_receive_ubl20"
  }

  def process_xml_file(raw_invoice,company,from="",md5)
    @company = company
    doc = REXML::Document.new(raw_invoice.read.chomp)
    facturae_version = REXML::XPath.first(doc,"//FileHeader/SchemaVersion")
    ubl_version = REXML::XPath.first(doc,"//Invoice/*:UBLVersionID")
    xpaths = {}
    channel=""
    if facturae_version
      invoice_format="facturae#{facturae_version.text}"
      logger.info "Incoming invoice is FacturaE #{facturae_version.text}"
      xpaths[:invoice_number]          = [ "//Invoices/Invoice/InvoiceHeader/InvoiceNumber",
        "//Invoices/Invoice/InvoiceHeader/InvoiceSeriesCode" ]
      xpaths[:invoice_date]            = "//Invoices/Invoice/InvoiceIssueData/IssueDate"
      xpaths[:invoice_total]           = "//Invoices/Invoice/InvoiceTotals/InvoiceTotal"
      xpaths[:invoice_import]          = "//Invoices/Invoice/InvoiceTotals/TotalGrossAmountBeforeTaxes"
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
      logger.info "Incoming invoice is UBL #{ubl_version.text}"
      xpaths[:invoice_number]          = "/Invoice/cbc:ID"
      xpaths[:invoice_date]            = "/Invoice/cbc:IssueDate"
      xpaths[:invoice_total]           = "/Invoice/cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount"
      xpaths[:invoice_import]          = "/Invoice/cac:LegalMonetaryTotal/cbc:TaxExclusiveAmount"
      xpaths[:invoice_due_date]        = "/Invoice/cac:PaymentMeans/cbc:PaymentDueDate"
      xpaths[:seller_taxcode]          = "/Invoice/cac:AccountingSupplierParty/cac:Party/cac:PartyTaxScheme/cbc:CompanyID"
      xpaths[:seller_name]             = "/Invoice/cac:AccountingSupplierParty/cac:Party/cac:PartyName/cbc:Name"
      xpaths[:seller_name2]            = nil
      xpaths[:seller_address]          = [ "/Invoice/cac:AccountingSupplierParty/cac:Party/cac:PostalAddress/cbc:StreetName",
	  "/Invoice/cac:AccountingSupplierParty/cac:Party/cac:PostalAddress/cbc:BuildingNumber" ] 
      xpaths[:seller_province]         = "/Invoice/cac:AccountingSupplierParty/cac:Party/cac:PostalAddress/cbc:CountrySubentity"
      xpaths[:seller_countrycode]      = "/Invoice/cac:AccountingSupplierParty/cac:Party/cac:PostalAddress/cac:Country/cbc:IdentificationCode"
      xpaths[:seller_website]          = "/Invoice/cac:AccountingSupplierParty/cac:Party/cbc:WebsiteURI"
      xpaths[:seller_email]            = "/Invoice/cac:AccountingSupplierParty/cac:Party/cac:Contact/cbc:ElectronicMail"
      xpaths[:seller_cp_city]          = [ "/Invoice/cac:AccountingSupplierParty/cac:Party/cac:PostalAddress/cbc:PostalZone",
	  "/Invoice/cac:AccountingSupplierParty/cac:Party/cac:PostalAddress/cbc:CityName" ]
      xpaths[:seller_cp_city2]         = nil
      xpaths[:buyer_taxcode]           = "/Invoice/cac:AccountingCustomerParty/cac:Party/cac:PartyTaxScheme/cbc:CompanyID"
      xpaths[:currency]                = "/Invoice/cbc:DocumentCurrencyCode"
      ch_name = @@channels[invoice_format]
      if ch_name
        channel="/var/spool/b2brouter/input/#{ch_name}"
      end
    else
      logger.info "Incoming invoice with unknown format"
      #TODO: bounce message
    end

    #TODO: check buyer_taxcode == company.taxcode
    #    buyer_taxcode  = get_xpath(doc,xpaths[:buyer_taxcode])
    #    company = Company.find_by_taxcode(buyer_taxcode)
    #    raise "Company with taxcode '#{buyer_taxcode}' not found" unless company #TODO: bounce message

    seller_taxcode = get_xpath(doc,xpaths[:seller_taxcode])
    client         = seller_taxcode.blank? ? nil : @company.project.clients.find_by_taxcode(seller_taxcode)
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
                          :project        => @company.project)
      client.save(:validate=>false)
    end
    invoice_number      = get_xpath(doc,xpaths[:invoice_number])
    invoice_date        = get_xpath(doc,xpaths[:invoice_date])
    invoice_total       = get_xpath(doc,xpaths[:invoice_total])
    invoice_import      = get_xpath(doc,xpaths[:invoice_import])
    invoice_due_date    = get_xpath(doc,xpaths[:invoice_due_date])

    ri = ReceivedInvoice.new(:number          => invoice_number,
                            :client          => client,
                            :date            => invoice_date,
                            :total           => invoice_total.to_money(currency),
                            :currency        => currency,
                            :import          => invoice_import.to_money(currency),
                            :due_date        => invoice_due_date,
                            :project         => @company.project)

    ri.invoice_format = invoice_format
    ri.transport='email'
    ri.from=from
    ri.md5 = md5
    ri.original = raw_invoice.read.chomp
    ri.file_name = raw_invoice.filename
    ri.save!
    return ri
  rescue Exception => e
    logger.info e.message
  end


  def process_pdf_file(raw_invoice,company,from="",md5)
    @company = company

    # PDF attachment has #<Encoding:ASCII-8BIT>
    # without force_encoding write halts with: "\xFE" from ASCII-8BIT to UTF-8
    attachment = raw_invoice.read.chomp
    attachment.force_encoding('UTF-8')
    tmpfile = Tempfile.new "pdf"
    tmpfile.write(attachment)
    tmpfile.close

    text_file = Tempfile.new "txt"
    cmd = "pdftotext -f 1 -l 1 -layout #{tmpfile.path} #{text_file.path}"
    out = `#{cmd} 2>&1`
    raise "Error with pdftotext <br /><pre>#{cmd}</pre><pre>#{out}</pre>" unless $?.success?
    ds = Estructura::Invoice.new(text_file.read.chomp,:tax_id=>@company.taxcode)
    text_file.close
    text_file.unlink
    ds.apply_rules
    ds.fix_amounts
    client = Client.find(:all, :conditions => ["project_id = ? AND taxcode = ?",@company.project_id,ds.tax_identification_number]).first
    ri = ReceivedInvoice.new(:number          => ds.invoice_number,
                            :client          => client,
                            :date            => ds.issue_date,
                            :import          => ds.total_amount.to_money,
#                            :currency        => ds.currency,
#                            :tax_percent     => ds.tax_rate,
#                            :subtotal        => ds.invoice_subtotal.to_money,
#                            :withholding_tax => ds.withholding_tax.to_money,
                            :due_date        => ds.due_date,
                            :project         => @company.project)

    ri.md5 = `md5sum #{tmpfile.path} | cut -d" " -f1`.chomp
    ri.transport='email'
    ri.from=from
    ri.invoice_format = "pdf"
    ri.original = raw_invoice.read.chomp
    ri.file_name = raw_invoice.filename
    ri.save!
    return ri
  rescue Exception => e
    logger.info e.message
  end


  private

  # retrieve xpath from document
  # if xpath is an array, concatenates its values
  def get_xpath(doc,xpath)
    val=""
    if xpath.is_a?(Array)
      xpath.each do |xp|
        txt = REXML::XPath.first(doc,xp).text.to_s rescue ""
        unless txt.blank?
          val += txt
          val += " " unless xp == xpath.last
        end
      end
    elsif xpath.nil?
      nil
    else
      val += REXML::XPath.first(doc,xpath).text.to_s rescue ""
    end
    val.blank? ? nil : val
  end

  def attached_invoices(email)
    invoices = []
    email.attachments.each do |attachment|
      invoices << attachment if attachment.content_type =~ /xml/ || attachment.content_type =~ /pdf/
    end
    email.parts.each do |part|
      attached_mail = nil
      attached_mail = TMail::Mail.parse(part.body) if email.attachment?(part) rescue nil
      next if attached_mail.nil? || attached_mail.attachments.nil?
      attached_mail.attachments.each do |attachment|
        invoices << attachment if attachment.content_type =~ /xml/ || attachment.content_type =~ /pdf/
      end
    end
    invoices
  end

end
