class IncomingPdfInvoice

  def self.process_file(invoice,company,transport,from="")
    @company = company
    ri = invoice_from_pdf(invoice)
    ri.transport=transport
    ri.from=from
    ri.invoice_format = "pdf"
    ri.md5 = Digest::MD5.hexdigest(invoice.read)
    ri.save!
    channel="/var/spool/b2brouter/input/free_receive_pdf"
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

  def self.invoice_from_pdf(pdf)
    require "tempfile"
    pdf_file = Tempfile.new "pdf"
    pdf_file.write(pdf.read)
    pdf_file.close
    pdf.rewind
    text_file = Tempfile.new "txt"
    cmd = "pdftotext -f 1 -l 1 -layout #{pdf_file.path} #{text_file.path}"
    out = `#{cmd} 2>&1`
    raise "Error with pdftotext <br /><pre>#{cmd}</pre><pre>#{out}</pre>" unless $?.success?
    html = `pdftohtml #{pdf_file.path} -i -stdout -noframes`.gsub(/^.*<body[^>]*>/mi,'').gsub(/<\/body[^>]*>.*$/mi,'')
    ds = Estructura::Invoice.new(text_file.read,:tax_id=>@company.taxcode)
    ds.apply_rules
    ds.fix_amounts
    client = Client.find(:all, :conditions => ["project_id = ? AND taxcode = ?",@company.project_id,ds.tax_identification_number]).first
    r = ReceivedInvoice.new(:number          => ds.invoice_number,
                            :client          => client,
                            :date            => ds.issue_date,
                            :import          => ds.total_amount.to_money,
#                            :currency        => ds.currency,
                            :tax_percent     => ds.tax_rate,
#                            :subtotal        => ds.invoice_subtotal.to_money,
#                            :withholding_tax => ds.withholding_tax.to_money,
                            :due_date        => ds.due_date,
                            :project         => @company.project,
                            :html            => html)
    return r
  end

end

