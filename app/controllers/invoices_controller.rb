class InvoicesController < ApplicationController

  unloadable
  menu_item :haltr

  helper :sort
  include SortHelper

  before_filter :find_invoice, :except => [:index,:new,:create,:destroy_payment]
  before_filter :find_project, :only => [:index,:new,:create]
  before_filter :find_payment, :only => [:destroy_payment]
  before_filter :authorize

  include CompanyFilter
  before_filter :check_for_company

  def index
    sort_init 'number', 'desc'
    sort_update %w(type state number date due_date clients.name import_in_cents)

    c = ARCondition.new(["invoices.project_id = ?",@project.id])

    unless params[:type] == "all"
      c << ["type='IssuedInvoice'"] if params[:type] == "issued"
      c << ["type='ReceivedInvoice'"] if params[:type] == "received"
    end

    unless params["state_all"] == "1"
      statelist=[]
      %w(new sending sent error closed discarded).each do |state|
        if params[state] == "1"
          statelist << "'#{state}'"
        end
      end
      if statelist.any?
        c << ["state in (#{statelist.join(",")})"]
      end
    end

    # client filter
    # TODO: change view collection_select (doesnt display previously selected client)
    unless params[:client_id].blank?
      c << ["client_id = ?", params[:client_id]]
    end

    # date filter
    unless params[:date_from].blank?
      c << ["date >= ?",params[:date_from]]
    end
    unless params["date_to"].blank?
      c << ["date <= ?",params[:date_to]]
    end

    @invoice_count = InvoiceDocument.count(:conditions => c.conditions, :include => [:client])
    @invoice_pages = Paginator.new self, @invoice_count,
		per_page_option,
		params['page']
    @invoices =  InvoiceDocument.find :all,
       :order => sort_clause,
       :conditions => c.conditions,
       :include => [:client],
       :limit  =>  @invoice_pages.items_per_page,
       :offset =>  @invoice_pages.current.offset
    render :action => "index", :layout => false if request.xhr?
  end

  def new
    @invoice = IssuedInvoice.new(:client_id=>params[:client],:project=>@project)
  end

  def edit
    @invoice = IssuedInvoice.find(params[:id])
  end

  def create
    @invoice = IssuedInvoice.new(params[:invoice])
    @invoice.project = @project
    if @invoice.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'show', :id => @invoice
    else
      render :action => "new"
    end
  end

  def update
    if @invoice.update_attributes(params[:invoice])
      Event.create(:name=>'edited',:invoice=>@invoice,:user=>User.current)
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'show', :id => @invoice
    else
      render :action => "edit"
    end
  end

  def destroy
    @invoice.destroy
    redirect_to :action => 'index', :id => @project
  end

  def destroy_payment
    @payment.destroy
    redirect_to :action => 'show', :id => @invoice
  end

  def mark_sent
    @invoice.manual_send
    redirect_to :back
  rescue ActionController::RedirectBackError => e
    render :text => "OK"
  end

  def mark_closed
    @invoice.close
    redirect_to :back
  rescue ActionController::RedirectBackError => e
    render :text => "OK"
  end

  def mark_not_sent
    @invoice.mark_unsent
    redirect_to :back
  rescue ActionController::RedirectBackError => e
    render :text => "OK"
  end

  def mark_accepted_with_mail
    MailNotifier.deliver_received_invoice_accepted(@invoice,params[:reason])
    mark_accepted
  end

  def mark_accepted
    @invoice.accept
    redirect_to :back
  rescue ActionController::RedirectBackError => e
    render :text => "OK"
  end

  def mark_refused_with_mail
    MailNotifier.deliver_received_invoice_refused(@invoice,params[:reason])
    mark_refused
  end

  def mark_refused
    @invoice.refuse
    redirect_to :back
  rescue ActionController::RedirectBackError => e
    render :text => "OK"
  end

  # create a template from an invoice
  def template
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

  def pdf
    pdf_file=Tempfile.new("invoice_#{@invoice.id}.pdf","tmp")
    xhtml_file=Tempfile.new("invoice_#{@invoice.id}.xhtml","tmp")
    xhtml_file.write(render_to_string(:action => "show", :layout => "invoice"))
    xhtml_file.close
    jarpath = "#{File.dirname(__FILE__)}/../../vendor/xhtmlrenderer"
    cmd="java -classpath #{jarpath}/core-renderer.jar:#{jarpath}/iText-2.0.8.jar:#{jarpath}/minium.jar org.xhtmlrenderer.simple.PDFRenderer #{RAILS_ROOT}/#{xhtml_file.path} #{RAILS_ROOT}/#{pdf_file.path}"
    out = `#{cmd} 2>&1`
    if $?.success?
      send_file(pdf_file.path, :filename => @invoice.pdf_name, :type => "application/pdf", :disposition => 'inline')
    else
      render :text => "Error in PDF creation <br /><pre>#{cmd}</pre><pre>#{out}</pre>"
    end
  end

  # methods to debugg xml
  def efactura30
    @company = @invoice.company
    render :template => 'invoices/facturae30.xml.erb', :layout => false
  end
  def efactura31
    @company = @invoice.company
    render :template => 'invoices/facturae31.xml.erb', :layout => false
  end
  def efactura32
    @company = @invoice.company
    render :template => 'invoices/facturae32.xml.erb', :layout => false
  end

  def show
    if @invoice.is_a? IssuedInvoice
      @invoices_not_sent = InvoiceDocument.find(:all,:conditions => ["client_id = ? and state = 'new'",@client.id]).sort
      @invoices_sent = InvoiceDocument.find(:all,:conditions => ["client_id = ? and state = 'sent'",@client.id]).sort
      @invoices_closed = InvoiceDocument.find(:all,:conditions => ["client_id = ? and state = 'closed'",@client.id]).sort
    elsif @invoice.is_a? ReceivedInvoice
      # TODO also show the database record version?
      # Redel XML with XSLT in browser
      @xsl = 'facturae32'
      render :template => 'invoices/show_with_xsl'
      #render :template => 'invoices/show_with_xsl_iframe'
    end
  end

  def send_invoice
    export_id = @invoice.client.invoice_format
    path = ExportChannels.path export_id
    format = ExportChannels.format export_id 
    @company = @invoice.company
    xml_file=Tempfile.new("invoice_#{@invoice.id}.xml","tmp")
    xml_file.write(render_to_string(:template => "invoices/#{format}.xml.erb", :layout => false))
    xml_file.close
    destination="#{path}/" + "#{@company.taxcode}_#{@invoice.id}.xml".gsub(/\//,'')
    i=2
    while File.exists? destination
      destination="#{path}/" + "#{@company.taxcode}_#{i}_#{@invoice.id}.xml".gsub(/\//,'')
      i+=1
    end
    FileUtils.mv(xml_file.path,destination)
    #TODO state restrictions
    @invoice.queue || @invoice.requeue
    flash[:notice] = l(:notice_invoice_sent)
  rescue Exception => e
    flash[:error] = "#{l(:error_invoice_not_sent)}: #{e.message}"
  ensure
    redirect_to :action => 'show', :id => @invoice
  end

  def legal
    #TODO: several B2bRouters
    #TODO: add params[:filename] to allow several filenames on one md5 (file.xml, file.pdf)
    if @invoice.fetch_legal_by_http
      respond_to do |format|
        format.html do
          send_data @invoice.legal_invoice, :filename => @invoice.legal_filename
        end 
        format.xml do
          render :xml => @invoice.legal_invoice
        end
      end
    else
      render_404
    end
  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH => e
    flash[:warning]=l(:cant_connect_trace, e.message)
    redirect_to :action => 'show', :id => @invoice
  end

  private

  def find_invoice
    @invoice = InvoiceDocument.find params[:id]
    @lines = @invoice.invoice_lines
    @client = @invoice.client || Client.new(:name=>"unknown",:countrycode=>"ESP",:taxcode=>"EUR",:project=>@invoice.project)
    @project = @invoice.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_payment
    @payment = Payment.find(params[:id])
    @invoice = @payment.invoice
    @project = @invoice.project
  end

end
