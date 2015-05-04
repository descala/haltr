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

  require "rexml/document"
  require "tempfile"

  def receive(email)
    invoices = []
    if email.multipart?
      raw_invoices = attached_invoices(email)

      if email.to and email.to.include? Setting.plugin_haltr['return_path']
        # bounced invoice
        Rails.logger.info "Bounced invoice mail received"
        invoices << process_bounce(email)
        Event.create(:name=>'bounced',:invoice=>invoices.first)
      else
        # incoming invoices (PDF/XML)
        Rails.logger.info "Incoming invoice mail with #{raw_invoices.size} attached invoices"
        company_found=false
        email['to'].to_s.scan(/[\w.]+@[\w.]+/).each do |to|
          company = Company.find_by_taxcode(to.split("@").first)
          company = Company.find_by_email(to) unless company
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
                Rails.logger.error "Discarding repeated invoice with md5 #{md5}. Invoice.id = #{found_invoice.id}"
              else
                if raw_invoice.content_type =~ /xml/
                  invoices << Invoice.create_from_xml(raw_invoice,company,from,md5,'email')
                  #TODO rescue and bounce?
                elsif raw_invoice.content_type =~ /pdf/
                  invoices << process_pdf_file(raw_invoice,company,md5,'email',from)
                else
                  Rails.logger.info "Discarding #{raw_invoice.filename} on incoming mail (#{raw_invoice.content_type})"
                end
              end
            end
            break #TODO: allow incoming invoice to several companies?
          end
        end
        unless company_found
          Rails.logger.info "Discarding email for #{email['to'].to_s} (Can't find any company)"
        end
      end
    else
      # we do not process emails without attachments
      Rails.logger.info "email has no attachments"
    end
    invoices
  end

  private

  def process_pdf_file(raw_invoice,company,from="",md5,transport)
    # assume invoices received by mail are always ReceivedInvoices
    @invoice           = ReceivedInvoice.new
    @invoice.project   = company.project
    @invoice.state     = :processing_pdf
    @invoice.transport = :email
    @invoice.md5       = md5
    @invoice.original  = raw_invoice.read
    @invoice.invoice_format = 'pdf'
    @invoice.save!(validate: false)
    Event.create(:name=>'processing_pdf',:invoice=>@invoice)
    Haltr::SendPdfToWs.send(@invoice)
    @invoice
  end

  def process_bounce(email)
    haltr_headers = Hash[*email.to_s.scan(/^X-Haltr.*$/).collect {|m|
      m.chomp.gsub(/: /,' ').split(" ")
    }.flatten] rescue {}
    # haltr sets invoice id on header
    id = haltr_headers["X-Haltr-Id"]
    # b2brouter sets invoice id on filename
    id ||= haltr_headers["X-Haltr-Filename"].split("_").last.split(".").first
    Invoice.find(id.to_i)
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
