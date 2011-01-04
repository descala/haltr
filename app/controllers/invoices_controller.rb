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

  before_filter :update_sending_invoices_state, :only => [:index,:showit]

  def index
    sort_init 'number', 'desc'
    sort_update %w(state number date due_date clients.name import_in_cents)

    c = ARCondition.new(["clients.project_id = ?",@project.id])

    unless params["state_all"] == "1"
      statelist=[]
      %w(new sending sent error closed).each do |state|
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
    @invoice = InvoiceDocument.new(:client_id=>params[:client])
  end

  def edit
    @invoice = InvoiceDocument.find(params[:id])
  end

  def create
    @invoice = InvoiceDocument.new(params[:invoice])
    if @invoice.save
      flash[:notice] = 'Invoice was successfully created.'
      redirect_to :action => 'showit', :id => @invoice
    else
      render :action => "new"
    end
  end

  def update
    if @invoice.update_attributes(params[:invoice])
      flash[:notice] = 'Invoice was successfully updated.'
      redirect_to :action => 'showit', :id => @invoice
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
    redirect_to :action => 'showit', :id => @invoice
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
    xhtml_file.write(render_to_string(:action => "showit", :layout => "invoice"))
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

  def efactura
    @company = @invoice.company
    render :template => 'invoices/facturae.xml.erb', :layout => false
  end

  def showit
    @invoices_not_sent = InvoiceDocument.find(:all,:conditions => ["client_id = ? and state = 'new'",@client.id]).sort
    @invoices_sent = InvoiceDocument.find(:all,:conditions => ["client_id = ? and state = 'sent'",@client.id]).sort
    @invoices_closed = InvoiceDocument.find(:all,:conditions => ["client_id = ? and state = 'closed'",@client.id]).sort
  end

  def send_invoice
    path=Setting.plugin_haltr["folder#{params[:folder]}"]
    unless path.blank?
      @company = @invoice.company
      xml_file=Tempfile.new("invoice_#{@invoice.id}.xml","tmp")
      xml_file.write(render_to_string(:template => "invoices/facturae.xml.erb", :layout => false))
      xml_file.close
      destination="#{path}/" + "#{@project.identifier}_#{@invoice.number}.xml".gsub(/\//,'')
      i=2
      while File.exists? destination
        destination="#{path}/" + "#{@project.identifier}_#{@invoice.number}_#{i}.xml".gsub(/\//,'')
        i+=1
      end
      @invoice.md5=`md5sum '#{xml_file.path}'`.split.first
      @invoice.channel=path.split("/").last
      #TODO: fer b2brouter_url diferent per a cada canal, doncs pot ser que hi hagi varis b2brouters
      @invoice.b2brouter_url=Setting.plugin_haltr["trace_url"]
      @invoice.create_b2b_message(File.basename(destination))
      FileUtils.mv(xml_file.path,destination)
      #TODO state restrictions
      @invoice.queue || @invoice.requeue
      flash[:info] = 'Invoice sent to the send queue'
      redirect_to :action => 'showit', :id => @invoice
    else
      flash[:error] = 'Unknown send type'
      redirect_to :action => 'showit', :id => @invoice
    end
  end

  def log
    B2bMessage.connect(@invoice.b2brouter_url)
    B2bLog.connect(@invoice.b2brouter_url)
    @message = @invoice.b2b_message
    @current_page = params[:page] || 1
    @messages_page = params[:messages_page]
    @sent=params[:sent]
    @logs = B2bLog.paginate(:all, :params => { :b2b_message_id=>@message.id, :page=>@current_page })
  end

  private

  def find_invoice
    @invoice = InvoiceDocument.find params[:id]
    @lines = @invoice.invoice_lines
    @client = @invoice.client
    @project = @client.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_payment
    @payment = Payment.find(params[:id])
    @invoice = @payment.invoice
    @project = @invoice.project
  end

  def update_sending_invoices_state
    if @invoice
      ii = [ @invoice ]
    else
      ii = InvoiceDocument.find :all, :conditions => ["clients.project_id = ? AND state='sending'",@project.id], :include => [:client]
    end
    ii.each do |i|
      b2bm = i.b2b_message
      next if b2bm.nil?
      if b2bm.sent == true
        i.success_sending
      elsif b2bm.sent == false
        i.error_sending
      end
    end
  end

end
