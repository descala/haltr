class IncomingPdfInvoice

  require "tempfile"

  def self.process_file(invoice,company,transport,from="")
    @company = company

    # PDF attachment has #<Encoding:ASCII-8BIT>
    # without force_encoding write halts with: "\xFE" from ASCII-8BIT to UTF-8
    attachment = invoice.read.chomp
    attachment.force_encoding('UTF-8')

    tmpfile = Tempfile.new "pdf"
    tmpfile.write(attachment)
    tmpfile.close
    ri = invoice_from_pdf(tmpfile.path)
    ri.md5 = `md5sum #{tmpfile.path} | cut -d" " -f1`.chomp
    ri.transport=transport
    ri.from=from
    ri.invoice_format = "pdf"
    ri.save!
    channel="/var/spool/b2brouter/input/free_receive_pdf"
    if File.directory? channel
      i=2
      extension = File.extname(invoice.filename)
      base = invoice.filename.gsub(/#{extension}$/,'')
        destination = "#{channel}/#{base}_#{ri.id}#{extension}"
      while File.exist? destination do
        destination = "#{channel}/#{base}_#{i}_#{ri.id}#{extension}"
        i+=1
      end
      FileUtils.mv(tmpfile.path, destination)
      InvoiceReceiver.log "Sent invoice to validation channel: #{destination} (MD5: #{ri.md5})"
    else
      InvoiceReceiver.log "Invoice format without validation channel #{channel}"
    end
  rescue Exception => e
    InvoiceReceiver.log e.message
  end

  def self.invoice_from_pdf(pdf_file_path)
    text_file = Tempfile.new "txt"
    cmd = "pdftotext -f 1 -l 1 -layout #{pdf_file_path} #{text_file.path}"
    out = `#{cmd} 2>&1`
    raise "Error with pdftotext <br /><pre>#{cmd}</pre><pre>#{out}</pre>" unless $?.success?
    ds = Estructura::Invoice.new(text_file.read.chomp,:tax_id=>@company.taxcode)
    text_file.close
    text_file.unlink
    ds.apply_rules
    ds.fix_amounts
    client = Client.find(:all, :conditions => ["project_id = ? AND taxcode = ?",@company.project_id,ds.tax_identification_number]).first
    r = ReceivedInvoice.new(:number          => ds.invoice_number,
                            :client          => client,
                            :date            => ds.issue_date,
                            :import          => ds.total_amount.to_money,
#                            :currency        => ds.currency,
#                            :tax_percent     => ds.tax_rate,
#                            :subtotal        => ds.invoice_subtotal.to_money,
#                            :withholding_tax => ds.withholding_tax.to_money,
                            :due_date        => ds.due_date,
                            :project         => @company.project)
    return r
  end

end

