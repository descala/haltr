class QuotesController < ApplicationController
  unloadable
  menu_item Haltr::MenuItem.new(:invoices,:quotes)
  helper :haltr
  helper :invoices
  layout 'haltr'
  before_filter :find_project_by_project_id, :except => [:show,:edit,:update,:destroy,:send_quote,:accept,:refuse]
  before_filter :find_invoice, :only => [:show,:edit,:update,:destroy,:send_quote,:accept,:refuse]
  before_filter :authorize

  helper :sort
  include SortHelper
  helper :attachments
  include AttachmentsHelper

  def index
    sort_init 'invoices.created_at', 'desc'
    sort_update %w(invoices.created_at state number date due_date clients.name import_in_cents)
    invoices = @project.quotes
    @invoice_count = invoices.count
    @invoice_pages = Paginator.new self, @invoice_count,
		per_page_option,
		params['page']
    @invoices =  invoices.find :all,
       :order => sort_clause,
       :include => [:client],
       :limit  =>  @invoice_pages.items_per_page,
       :offset =>  @invoice_pages.current.offset
  end

  def show
    respond_to do |format|
      format.html
      format.pdf do
        @is_pdf = true
        @debug = params[:debug]
        render :pdf => @invoice.pdf_name_without_extension,
          :disposition => 'attachment',
          :layout => "invoice.html",
          :template=>"quotes/show_pdf",
          :formats => :html,
          :show_as_html => params[:debug]
      end
      if params[:debug]
        format.facturae30  { render_xml Haltr::Xml.generate(@invoice, 'facturae30') }
        format.facturae31  { render_xml Haltr::Xml.generate(@invoice, 'facturae31') }
        format.facturae32  { render_xml Haltr::Xml.generate(@invoice, 'facturae32') }
        format.peppolubl20 { render_xml Haltr::Xml.generate(@invoice, 'peppolubl20') }
        format.peppolubl21 { render_xml Haltr::Xml.generate(@invoice, 'peppolubl21') }
        format.biiubl20    { render_xml Haltr::Xml.generate(@invoice, 'biiubl20') }
        format.svefaktura  { render_xml Haltr::Xml.generate(@invoice, 'svefaktura') }
        format.oioubl20    { render_xml Haltr::Xml.generate(@invoice, 'oioubl20') }
        format.efffubl     { render_xml Haltr::Xml.generate(@invoice, 'efffubl') }
      else
        format.facturae30  { download_xml Haltr::Xml.generate(@invoice, 'facturae30') }
        format.facturae31  { download_xml Haltr::Xml.generate(@invoice, 'facturae31') }
        format.facturae32  { download_xml Haltr::Xml.generate(@invoice, 'facturae32') }
        format.peppolubl20 { download_xml Haltr::Xml.generate(@invoice, 'peppolubl20') }
        format.peppolubl21 { download_xml Haltr::Xml.generate(@invoice, 'peppolubl21') }
        format.biiubl20    { download_xml Haltr::Xml.generate(@invoice, 'biiubl20') }
        format.svefaktura  { download_xml Haltr::Xml.generate(@invoice, 'svefaktura') }
        format.oioubl20    { download_xml Haltr::Xml.generate(@invoice, 'oioubl20') }
        format.efffubl     { download_xml Haltr::Xml.generate(@invoice, 'efffubl') }
      end
    end
  end

  def new
    @client = Client.find(params[:client]) if params[:client]
    @client ||= Client.find(:all, :order => 'name', :conditions => ["project_id = ?", @project]).first
    @client ||= Client.new
    @invoice = Quote.new(:project=>@project,:date=>Date.today,:number=>Quote.next_number(@project))
    il = InvoiceLine.new
    @project.company.taxes.each do |tax|
      il.taxes << Tax.new(:name=>tax.name, :percent=>tax.percent) if tax.default
    end
    @invoice.invoice_lines << il
  end

  def create
    # mark as "_destroy" all taxes with an empty tax code
    # and copy global "exempt comment" to all exempt taxes
    parsed_params = params[:invoice]
    if parsed_params["invoice_lines_attributes"]
      parsed_params["invoice_lines_attributes"].each do |i, invoice_line|
        if invoice_line["taxes_attributes"]
          invoice_line["taxes_attributes"].each do |j, tax|
            tax['_destroy'] = 1 if tax["code"].blank?
            if tax["code"] =~ /_E$/
              tax['comment'] = params["#{tax["name"]}_comment"]
            else
              tax['comment'] = ''
            end
          end
        end
      end
    end

    @invoice = Quote.new(parsed_params)
    if @invoice.invoice_lines.empty?
      il = InvoiceLine.new
      @project.company.taxes.each do |tax|
        il.taxes << Tax.new(:name=>tax.name, :percent=>tax.percent) if tax.default
      end
      @invoice.invoice_lines << il
    end
    @client = @invoice.client
    @invoice.project = @project
    if @invoice.save
      flash[:notice] = l(:notice_successful_create)
      if params[:create_and_send]
        if @invoice.valid?
          redirect_to :action => 'send_quote', :id => @invoice
        else
          flash[:error] = l(:errors_prevented_quote_sent)
          redirect_to :action => 'show', :id => @invoice
        end
      else
        redirect_to :action => 'show', :id => @invoice
      end
    else
      logger.info "Invoice errors #{@invoice.errors.full_messages}"
      # Add a client in order to render the form with the errors
      @client ||= Client.find(:all, :order => 'name', :conditions => ["project_id = ?", @project]).first
      @client ||= Client.new
      render :action => "new"
    end
  end

  def edit
  end

  def update
    #TODO: need to access invoice taxes before update_attributes, if not
    # updated taxes are not saved.
    # maybe related to https://rails.lighthouseapp.com/projects/8994/tickets/4642
    @invoice.invoice_lines.each {|l| l.taxes.each {|t| } }

    # mark as "_destroy" all taxes with an empty tax code
    # and copy global "exempt comment" to all exempt taxes
    parsed_params = params[:invoice]
    parsed_params["invoice_lines_attributes"] ||= {}
    parsed_params["invoice_lines_attributes"].each do |i, invoice_line|
      if invoice_line["taxes_attributes"]
        invoice_line["taxes_attributes"].each do |j, tax|
          tax['_destroy'] = 1 if tax["code"].blank?
          if tax["code"] =~ /_E$/
            tax['comment'] = params["#{tax["name"]}_comment"]
          else
            tax['comment'] = ''
          end
        end
      end
    end

    if @invoice.update_attributes(parsed_params)
      Event.create(:name=>'edited',:invoice=>@invoice,:user=>User.current)
      flash[:notice] = l(:notice_successful_update)
      if params[:save_and_send]
        if @invoice.valid?
          redirect_to :action => 'send_quote', :id => @invoice
        else
          flash[:error] = l(:errors_prevented_quote_sent)
          redirect_to :action => 'show', :id => @invoice
        end
      else
        redirect_to :action => 'show', :id => @invoice
      end
    else
      render :action => "edit"
    end
  end

  def destroy
    @invoice.destroy
    redirect_to :action => 'index', :project_id => @project
  end

  def send_quote
    unless @invoice.class.include?(Haltr::Validator::Mail) and @invoice.valid? #TODO aixo no funciona...
      raise @invoice.errors.full_messages.join(", ") # unless @invoice.valid?(:pdf_by_mail)
    end
    Delayed::Job.enqueue Haltr::SendPdfByMail.new(@invoice,User.current)
    @invoice.quote_send
    flash[:notice] = "#{l(:notice_quote_sent)}"
  rescue Exception => e
    flash[:error] = "#{l(:error_quote_not_sent, :num=>@invoice.number)}: #{e.message}"
    #raise e if Rails.env == "development"
  ensure
    redirect_back_or_default(:action => 'show', :id => @invoice)
  end

  def accept
    @quote = @invoice
    @quote.quote_accept
    @client = @quote.client
    @invoice = IssuedInvoice.new
    @invoice.attributes = @quote.attributes
    @invoice.number=IssuedInvoice.next_number(@project)
    @quote.invoice_lines.each do |line|
      il = line.dup
      il.taxes = line.taxes.collect {|tax| tax.dup}
      @invoice.invoice_lines << il
    end
    @invoice.quote_id = @quote.id
    @dest_controller = 'invoices'

    render 'invoices/new'
  end

  def refuse
    @invoice.quote_refuse
    redirect_to :action => 'index', :project_id => @project
  end

  private

  def find_invoice
    @invoice = Quote.find params[:id]
    @lines = @invoice.invoice_lines
    @client = @invoice.client || Client.new(:name=>"unknown",:project=>@invoice.project)
    @project = @invoice.project
    @company = @project.company
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
