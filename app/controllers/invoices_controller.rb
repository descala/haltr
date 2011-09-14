class InvoicesController < ApplicationController

  unloadable
  menu_item :haltr_invoices
  helper :haltr
  layout 'haltr'

  helper :sort
  include SortHelper

  before_filter :find_invoice, :except => [:index,:new,:create,:destroy_payment,:update_currency_select,:by_taxcode_and_num,:view,:logo,:download]
  before_filter :find_project, :only => [:index,:new,:create,:update_currency_select]
  before_filter :find_payment, :only => [:destroy_payment]
  before_filter :find_hashid, :only => [:view,:download]
  before_filter :find_attachment, :only => [:logo]
  before_filter :set_iso_countries_language
  before_filter :authorize, :except => [:by_taxcode_and_num,:view,:logo,:download]
  skip_before_filter :check_if_login_required, :only => [:by_taxcode_and_num,:view,:logo,:download]
  before_filter :check_remote_ip, :only => [:by_taxcode_and_num]

  include CompanyFilter
  before_filter :check_for_company, :except => [:by_taxcode_and_num,:view,:download]

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
      @client_id = params[:client_id].to_i rescue nil
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
    @client = Client.find(params[:client]) if params[:client]
    @client ||= Client.find(:all, :order => 'name', :conditions => ["project_id = ?", @project]).first
    @client ||= Client.new
    @invoice = IssuedInvoice.new(:client=>@client,:project=>@project,:date=>Date.today,:number=>IssuedInvoice.next_number(@project))
    @invoice.currency = @client.currency
  end

  def edit
    @invoice = InvoiceDocument.find(params[:id])
  end

  def create
    @invoice = IssuedInvoice.new(params[:invoice])
    @client = @invoice.client
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
    Event.create(:name=>'accept',:invoice=>@invoice,:user=>User.current,:info=>params[:reason])
    redirect_to :back
  rescue ActionController::RedirectBackError => e
    render :text => "OK"
  end

  def mark_refused_with_mail
    MailNotifier.deliver_received_invoice_refused(@invoice,params[:reason])
    mark_refused
  end

  def mark_refused
    Event.create(:name=>'refuse',:invoice=>@invoice,:user=>User.current,:info=>params[:reason])
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
  def ubl21
    @company = @invoice.company
    render :template => 'invoices/ubl21.xml.erb', :layout => false
  end

  def show
    if @invoice.is_a? IssuedInvoice
      @invoices_not_sent = InvoiceDocument.find(:all,:conditions => ["client_id = ? and state = 'new'",@client.id]).sort
      @invoices_sent = InvoiceDocument.find(:all,:conditions => ["client_id = ? and state = 'sent'",@client.id]).sort
      @invoices_closed = InvoiceDocument.find(:all,:conditions => ["client_id = ? and state = 'closed'",@client.id]).sort
    elsif @invoice.is_a? ReceivedInvoice
      if @invoice.invoice_format == "pdf"
        render :template => 'invoices/show_pdf'
      else
        # TODO also show the database record version?
        # Redel XML with XSLT in browser
        @xsl = 'facturae32'
        render :template => 'invoices/show_with_xsl'
      end
    end
  end

  def send_invoice
    raise @invoice.export_errors.collect {|e| l(e)}.join(", ") unless @invoice.can_be_exported?
    export_id = @invoice.client.invoice_format
    path = ExportChannels.path export_id
    format = ExportChannels.format export_id
    @company = @invoice.company
    xml_file=Tempfile.new("invoice_#{@invoice.id}.xml","tmp")
    xml_file.write(render_to_string(:template => "invoices/#{format}.xml.erb", :layout => false))
    xml_file.close
    destination="#{path}/" + "#{@invoice.client.hashid}_#{@invoice.id}.xml".gsub(/\//,'')
    i=2
    while File.exists? destination
      destination="#{path}/" + "#{@invoice.client.hashid}_#{i}_#{@invoice.id}.xml".gsub(/\//,'')
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
    download
  end

  def update_currency_select
    @client = Client.find(params[:value]) unless params[:value].blank?
    selected = @client.nil? ? params[:curr_sel] : @client.currency
    if params[:required] == "false"
      render :partial => "received_invoices/currency", :locals => {:selected=>selected}
    else
      render :partial => "payment_stuff", :locals => {:client=>@client}
    end
  end

  def by_taxcode_and_num
    company = Company.find_by_taxcode params[:taxcode]
    if company
      project = company.project
      number = params[:num]
      invoice = IssuedInvoice.find(:all,:conditions=>["number = ? AND project_id = ?",number,project.id]).first if project
    end
    if invoice.nil?
      render_404
    else
      respond_to do |format|
        format.html { render :text => invoice.nil? ? render_404 : invoice.id }
        format.xml { render :xml => invoice.nil? ? render_404 : invoice }
      end
    end
  end

  def view
    @lines = @invoice.invoice_lines
    @invoices_not_sent = []
    @invoices_sent = IssuedInvoice.find(:all,:conditions => ["client_id = ? and state = 'sent'",@client.id]).sort
    @invoices_closed = IssuedInvoice.find(:all,:conditions => ["client_id = ? and state = 'closed'",@client.id]).sort
    render :layout=>"public"
  rescue ActionView::MissingTemplate
    nil
  rescue
    render_404
  end

  def logo
    if @attachment.image?
      send_file @attachment.diskfile, :filename => filename_for_content_disposition(@attachment.filename),
        :type => @attachment.content_type,
        :disposition => 'inline'
    else
      render_404
    end
  end

  def download
    #TODO: several B2bRouters
    if @invoice.fetch_legal_by_http(params[:md5])
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

  def amend_for_invoice
    amend = @invoice.create_amend
    redirect_to :action => 'edit', :id => amend
  end

  private

  def find_hashid
    Project.send(:include, ProjectHaltrPatch) #TODO: perque nomes funciona el primer cop sense aixo?
    @client = Client.find_by_hashid params[:id]
    if @client.nil?
      render_404
      return
    end
    @company = @client.project.company
    invoices = IssuedInvoice.find(:all,
                                  :conditions => ["client_id=? AND id=?",@client.id,params[:invoice_id]]
                                 ).delete_if { |i| !i.visible_by_client? }
    if invoices.size != 1
      render_404
      return
    else
      @invoice = invoices.first
    end
  end

  def find_attachment
    @attachment = Attachment.find(params[:id])
    # Show 404 if the filename in the url is wrong
    raise ActiveRecord::RecordNotFound if params[:filename] && params[:filename] != @attachment.filename
    @project = @attachment.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_invoice
    Project.send(:include, ProjectHaltrPatch) #TODO: perque nomes funciona el primer cop sense aixo?
    @invoice = InvoiceDocument.find params[:id]
    @lines = @invoice.invoice_lines
    @client = @invoice.client || Client.new(:name=>"unknown",:project=>@invoice.project)
    @project = @invoice.project
    @company = @project.company
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_payment
    @payment = Payment.find(params[:id])
    @invoice = @payment.invoice
    @project = @invoice.project
  end

  def set_iso_countries_language
    ISO::Countries.set_language I18n.locale.to_s
  end

  #TODO: duplicated code
  def check_remote_ip
    allowed_ips = Setting.plugin_haltr['b2brouter_ip'].gsub(/ /,'').split(",") << "127.0.0.1"
    unless allowed_ips.include?(request.remote_ip)
      render :text => "Not allowed from your IP #{request.remote_ip}\n", :status => 403
      logger.error "Not allowed from IP #{request.remote_ip} (allowed IPs: #{allowed_ips.join(', ')})\n"
      return false
    end
  end

end
