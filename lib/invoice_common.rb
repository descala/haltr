module InvoiceCommon

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
    jarpath = "vendor/xhtmlrenderer"
    cmd="java -classpath #{jarpath}/core-renderer.jar:#{jarpath}/iText-2.0.8.jar:#{jarpath}/minium.jar org.xhtmlrenderer.simple.PDFRenderer #{xhtml_file.path} #{pdf_file.path}"
    if system(cmd)
      send_file(pdf_file.path, :filename => @invoice.pdf_name, :type => "application/pdf", :disposition => 'inline')
    else
      render :text => "Error in PDF creation"
    end
  end
  
  def create_more
    @date = Time.now + 15.day
    templates = InvoiceTemplate.find :all, :conditions => ["date <= ?", @date]
    @invoices = []
    templates.each do |t|
      @invoices << t.next_invoice
    end
  end

  def automator
    @invoices = InvoiceDocument.find_not_sent
  end
  
  # generate spanish AEB Nº19
  def n19
    example_invoice = InvoiceDocument.find params[:id]
    @due_date = example_invoice.due_date
    @fecha_cargo = @due_date.to_formatted_s :ddmmyy
    @clients = Client.find :all, :conditions => "bank_account", :order => 'taxcode'
    @fecha_confeccion = Date.today.to_formatted_s :ddmmyy
    @total = Money.new 0
    @clients.each do |client|
      money = client.bank_invoices_total(@due_date)
      @clients = @clients - [client] if money.zero?
      @total += money
    end

    if @clients.size > 0
      response.headers['Content-type'] = "text; charset=utf-8"
      response.headers['Content-disposition'] = "attachment; filename=n19-#{@fecha_cargo[4..5]}-#{@fecha_cargo[2..3]}-#{@fecha_cargo[0..1]}.txt"
      render :layout => false
    else
      flash[:warning] = "No data for an Nº19"
      redirect_to :action => 'menu'
    end
  end
  
  def n19_done
    example_invoice = InvoiceDocument.find params[:id]
    invoices = InvoiceDocument.find :all, :conditions => ["due_date = ?",example_invoice.due_date]
    invoices.each do |invoice|
      invoice.status = Invoice::STATUS_CLOSED
      invoice.save
    end
    flash[:notice] = "Nº19 for due date #{example_invoice.due_date} maked as done"
    redirect_to :action => 'menu'
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
    index
  end

  def mark_closed
    find_invoice
    @invoice.mark_closed
    index
  end
  
  def mark_not_sent
    find_invoice
    @invoice.mark_not_sent
    index
  end
  
  def menu
    @num_new_invoices = InvoiceTemplate.all(:conditions => ["date <= ?", Time.now + 15.day]).size
    @num_not_sent = InvoiceDocument.find_not_sent.size
    @charge_bank_on_due_date = InvoiceDocument.find_due_dates
  end
  
  def report
    m = params[:id] || 3
    d = Date.today - m.to_i.months
    @date = Date.new(d.year,d.month,1)
    @invoices = InvoiceDocument.all(:conditions => ["date >= ?", @date], :order => :number)
    @total_amount = Money.new 0
    @total_tax = Money.new 0
    @invoices.each do |i|
      @total_amount +=  i.subtotal
      @total_tax    +=  i.tax
    end
  end
  
  def find_invoice
    @invoice=Invoice.find params[:id]
    if @invoice
      @client=@invoice.client
      @lines=@invoice.invoice_lines
    end
  end
  
end
