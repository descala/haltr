module InvoiceCommon

  unloadable
  def showit
    find_invoice
    render :template => "invoices/showit", :layout => 'invoice'
  end
  
  def pdf
    find_invoice
    pdf_file=Tempfile.new("invoice_#{@invoice.id}.pdf","tmp")
    xhtml_file=Tempfile.new("invoice_#{@invoice.id}.xhtml","tmp")
    xhtml_file.write(render_to_string(:action => "showit", :layout => "invoice"))
    xhtml_file.close
    jarpath = "#{File.dirname(__FILE__)}/../vendor/xhtmlrenderer"
    cmd="java -classpath #{jarpath}/core-renderer.jar:#{jarpath}/iText-2.0.8.jar:#{jarpath}/minium.jar org.xhtmlrenderer.simple.PDFRenderer #{RAILS_ROOT}/#{xhtml_file.path} #{RAILS_ROOT}/#{pdf_file.path}"
    out = `#{cmd} 2>&1`
    if $?.success?
      send_file(pdf_file.path, :filename => @invoice.pdf_name, :type => "application/pdf", :disposition => 'inline')
    else
      render :text => "Error in PDF creation <br /><pre>#{cmd}</pre><pre>#{out}</pre>"
    end
  end
  
  # create a template from an invoice
  def template
    find_invoice
    it = InvoiceTemplate.new @invoice.attributes
    it.frequency = 1
    it.number = nil
    it.save!
    # copy template lines
    @invoice.invoice_lines.each do |il|
      l = InvoiceLine.new il.attributes
      l.invoice = it
      l.save!
    end
    
    render :text => "Template created"
  end
  
  def mark_sent
    find_invoice
    @invoice.mark_sent
    redirect_to :action => 'index', :id => @project
  end

  def mark_closed
    find_invoice
    @invoice.mark_closed
    redirect_to :action => 'index', :id => @project
  end
  
  def mark_not_sent
    find_invoice
    @invoice.mark_not_sent
    redirect_to :action => 'index', :id => @project
  end
  
  def find_invoice
    @invoice=Invoice.find params[:id]
    if @invoice
      @client=@invoice.client
      @lines=@invoice.invoice_lines
    end
  end
  
end
