class InvoicesController < ApplicationController

  include InvoiceCommon

  unloadable
  menu_item :haltr

  helper :sort
  include SortHelper

  before_filter :find_project, :only => [:index,:new,:create]
  before_filter :find_invoice, :except => [:index,:new,:create]

  def index
    sort_init 'number', 'desc'
    sort_update %w(status date number clients.name)

    c = ARCondition.new

    unless params[:name].blank?
      name = "%#{params[:name].strip.downcase}%"
      c << ["LOWER(name) LIKE ? OR LOWER(address1) LIKE ? OR LOWER(address2) LIKE ?", name, name, name]
    end

    @invoice_count = InvoiceDocument.count(:conditions => c.conditions)
    @invoice_pages = Paginator.new self, @invoice_count,
		per_page_option,
		params['page']
    @invoices =  InvoiceDocument.find :all,:order => sort_clause,
       :conditions => c.conditions,
       :include => [:client],
       :limit  =>  @invoice_pages.items_per_page,
       :offset =>  @invoice_pages.current.offset

    render :action => "index", :layout => false if request.xhr?
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

end
