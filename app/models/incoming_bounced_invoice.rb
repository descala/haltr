class IncomingBouncedInvoice

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
