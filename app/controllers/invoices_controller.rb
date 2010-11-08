class InvoicesController < ApplicationController

  unloadable
  menu_item :haltr

  helper :sort
  include SortHelper

  before_filter :find_invoice, :except => [:index,:new,:create,:for_client]
  before_filter :find_project, :only => [:index,:new,:create]
  before_filter :find_client, :only => [:for_client]
  before_filter :authorize

  def index
    sort_init 'number', 'desc'
    sort_update %w(status date number clients.name)

    c = ARCondition.new(["clients.project_id = ?",@project.id])

    unless params[:name].blank?
      name = "%#{params[:name].strip.downcase}%"
      c << ["LOWER(name) LIKE ? OR LOWER(address1) LIKE ? OR LOWER(address2) LIKE ?", name, name, name]
    end

    if @client
      c << ["client_id = ?", @client.id]
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
  end

  def for_client
    index
    render :action => 'index'
  end

  def new
    @invoice = InvoiceDocument.new
    @invoice.client_id = params[:client]
  end

  def edit
    @invoice = InvoiceDocument.find(params[:id])
  end

  def create
    @invoice = InvoiceDocument.new(params[:invoice])
    if @invoice.save
      flash[:notice] = 'Invoice was successfully created.'
      redirect_to :action => 'index', :id => @project
    else
      render :action => "new"
    end
  end

  def update
    if @invoice.update_attributes(params[:invoice])
      flash[:notice] = 'Invoice was successfully updated.'
      redirect_to :action => 'index', :id => @project
    else
      render :action => "edit"
    end
  end

  def destroy
    @invoice.destroy
    redirect_to :action => 'index', :id => @project
  end

  def mark_sent
    find_invoice
    @invoice.mark_sent
    redirect_to :back
  end

  def mark_closed
    find_invoice
    @invoice.mark_closed
    redirect_to :back
  end

  def mark_not_sent
    find_invoice
    @invoice.mark_not_sent
    redirect_to :back
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

  def pdf
    find_invoice
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

  def showit
    @invoices_not_sent = InvoiceDocument.find(:all,:conditions => ["client_id = ? and status = ?",@client.id,Invoice::STATUS_NOT_SENT]).sort
    @invoices_sent = InvoiceDocument.find(:all,:conditions => ["client_id = ? and status = ?",@client.id,Invoice::STATUS_SENT]).sort
    @invoices_closed = InvoiceDocument.find(:all,:conditions => ["client_id = ? and status = ?",@client.id,Invoice::STATUS_CLOSED]).sort
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

  def find_project
    begin
      @project = Project.find(params[:id])
      logger.info "Project #{@project.name}"
    rescue ActiveRecord::RecordNotFound
      render_404
    end
  end

  def find_client
    begin
      @client = Client.find(params[:id])
      @project = @client.project
      logger.info "Project #{@project.name}"
    rescue ActiveRecord::RecordNotFound
      render_404
    end
  end

end
