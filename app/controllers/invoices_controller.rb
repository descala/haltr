class InvoicesController < ApplicationController

  unloadable
  menu_item Haltr::MenuItem.new(:invoices,:invoices_level2)
  menu_item Haltr::MenuItem.new(:invoices,:reports), :only => [:reports, :report_channel_state, :report_invoice_list]
  helper :haltr
  helper :context_menus
  layout 'haltr'

  helper :sort
  include SortHelper
  helper :attachments
  include AttachmentsHelper

  PUBLIC_METHODS = [:by_taxcode_and_num,:view,:download,:mail,:logo,:haltr_sign]

  before_filter :find_project_by_project_id, :only => [:index,:new,:create,:send_new_invoices,:download_new_invoices,:update_payment_stuff,:new_invoices_from_template,:reports,:report_channel_state,:report_invoice_list,:create_invoices,:update_taxes,:import,:import_facturae]
  before_filter :find_invoice, :only => [:edit,:update,:mark_accepted_with_mail,:mark_accepted,:mark_refused_with_mail,:mark_refused,:duplicate_invoice,:base64doc,:show,:send_invoice,:legal,:amend_for_invoice,:original,:validate,:show_original, :mark_as_accepted, :mark_as, :add_comment]
  before_filter :find_invoices, :only => [:context_menu,:bulk_download,:bulk_mark_as,:bulk_send,:destroy,:bulk_validate]
  before_filter :find_payment, :only => [:destroy_payment]
  before_filter :find_hashid, :only => [:view,:download]
  before_filter :find_attachment, :only => [:logo]
  before_filter :set_iso_countries_language
  before_filter :find_invoice_by_number, only: [:number_to_id]
  before_filter :authorize, :except => PUBLIC_METHODS
  skip_before_filter :check_if_login_required, :only => PUBLIC_METHODS
  # on development skip auth so we can use curl to debug
  if Rails.env.development? or Rails.env.test?
    skip_before_filter :check_if_login_required, :only => [:by_taxcode_and_num,:view,:download,:mail,:show,:original]
    skip_before_filter :authorize, :only => [:show,:original]
  else
    before_filter :check_remote_ip, :only => [:by_taxcode_and_num,:mail]
  end
  before_filter :redirect_to_correct_controller, :only => [:show]

  include CompanyFilter
  before_filter :check_for_company, :except => PUBLIC_METHODS

  skip_before_filter :verify_authenticity_token, :only => [:base64doc]
  accept_api_auth :import, :import_facturae, :number_to_id, :update, :show, :index, :destroy, :create

  def index
    sort_init 'invoices.created_at', 'desc'
    sort_update %w(invoices.created_at state_updated_at number date due_date clients.name import_in_cents)

    invoices = @project.issued_invoices.includes(:client)

    if params[:invoices]
      invoices = invoices.where(["invoices.id in (?)",params[:invoices]])
    end

    unless params["state_all"] == "1"
      statelist=[]
      %w(new sending sent error closed discarded registered refused accepted allegedly_paid).each do |state|
        if params[state] == "1"
          statelist << "'#{state}'"
        end
      end
      if statelist.any?
        invoices = invoices.where("state in (#{statelist.join(",")})")
      end
    end

    # client filter
    # TODO: change view collection_select (doesnt display previously selected client)
    unless params[:client_id].blank?
      invoices = invoices.where("client_id = ?", params[:client_id])
      @client_id = params[:client_id].to_i rescue nil
    end

    # date filter
    unless params[:date_from].blank?
      invoices = invoices.where("date >= ?",params[:date_from])
    end
    unless params["date_to"].blank?
      invoices = invoices.where("date <= ?",params[:date_to])
    end

    # due_date filter
    unless params[:due_date_from].blank?
      invoices = invoices.where("due_date >= ?",params[:due_date_from])
    end
    unless params[:due_date_to].blank?
      invoices = invoices.where("due_date <= ?",params[:due_date_to])
    end

    unless params[:taxcode].blank?
      invoices = invoices.where("clients.taxcode like ?","%#{params[:taxcode]}%")
    end
    unless params[:name].blank?
      invoices = invoices.where("clients.name like ?","%#{params[:name]}%")
    end
    unless params[:number].blank?
      if params[:number] =~ /,/
        invoices = invoices.where("number in (?)",params[:number].split(',').collect {|n| n.strip})
      else
        invoices = invoices.where("number like ?","%#{params[:number]}%")
      end
    end

    unless params[:state_updated_at_from].blank?
      invoices = invoices.where("state_updated_at >= ?", params[:state_updated_at_from])
    end

    if params[:format] == 'csv' and !User.current.allowed_to?(:export_invoices, @project)
      @status= l(:contact_support)
      @message=l(:notice_not_authorized)
      render :template => 'common/error', :layout => 'base', :status => 403, :formats => [:html]
      return
    end

    case params[:format]
    when 'csv', 'pdf'
      @limit = Setting.issues_export_limit.to_i
    when 'xml', 'json'
      @offset, @limit = api_offset_and_limit
    else
      @limit = per_page_option
    end

    @invoice_count = invoices.count
    @invoice_pages = Paginator.new self, @invoice_count, @limit, params['page']
    @offset ||= @invoice_pages.offset
    @invoices =  invoices.find(:all,
                               :order => sort_clause,
                               :include => [:client],
                               :limit  =>  @limit,
                               :offset =>  @offset)

    respond_to do |format|
      format.html
      format.api
      format.csv do
        @invoices = invoices.order(sort_clause)
      end
    end

  end

  def new
    @client = Client.find(params[:client]) if params[:client]
    @client ||= Client.find(:all, :order => 'name', :conditions => ["project_id = ?", @project]).first
    @client ||= Client.new(:country=>@project.company.country,
                           :currency=>@project.company.currency,
                           :language=>User.current.language)
    @invoice = invoice_class.new(:client=>@client,:project=>@project,:date=>Date.today,:number=>IssuedInvoice.next_number(@project))
    @invoice.currency = @client.currency
    il = InvoiceLine.new
    @project.company.taxes.each do |tax|
      il.taxes << Tax.new(:name=>tax.name, :percent=>tax.percent) if tax.default
    end
    @invoice.invoice_lines << il
  end

  def edit
    if params[:created_client_id]
      @created_client = Client.find params[:created_client_id]
    end
  end

  def create
    # mark as "_destroy" all taxes with an empty tax code
    # and copy global "exempt comment" to all exempt taxes
    parsed_params = parse_invoice_params

    @invoice = invoice_class.new(parsed_params)
    @invoice.save_attachments(params[:attachments] || (params[:invoice] && params[:invoice][:uploads]))
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
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          if params[:create_and_send]
            if @invoice.valid?
              if ExportChannels[@invoice.client.invoice_format]['javascript']
                # channel sends via javascript, set autocall and autocall_args
                # 'show' action will set a div to tell javascript to automatically
                # call this function
                js = ExportChannels[@invoice.client.invoice_format]['javascript'].
                  gsub(':id',@invoice.id.to_s).gsub(/'/,"").split(/\(|\)/)
                redirect_to :action => 'show', :id => @invoice,
                  :autocall => js[0].html_safe, :autocall_args => js[1]
              else
                redirect_to :action => 'send_invoice', :id => @invoice
              end
            else
              flash[:error] = l(:errors_prevented_invoice_sent)
              redirect_to :action => 'show', :id => @invoice
            end
          else
            redirect_to :action => 'show', :id => @invoice
          end
        }
        format.api { render :action => 'show', :status => :created, :location => invoice_url(@invoice) }
      end
    else
      logger.info "Invoice errors #{@invoice.errors.full_messages}"
      # Add a client in order to render the form with the errors
      @client ||= Client.find(:all, :order => 'name', :conditions => ["project_id = ?", @project]).first
      @client ||= Client.new

      respond_to do |format|
        format.html { render :action => 'new' }
        format.api { render_validation_errors(@invoice) }
      end
    end
  end

  def update
    @invoice.save_attachments(params[:attachments] || (params[:invoice] && params[:invoice][:uploads]))

    #TODO: need to access invoice taxes before update_attributes, if not
    # updated taxes are not saved.
    # maybe related to https://rails.lighthouseapp.com/projects/8994/tickets/4642
    @invoice.invoice_lines.each {|l| l.taxes.each {|t| } }

    # mark as "_destroy" all taxes with an empty tax code
    # and copy global "exempt comment" to all exempt taxes
    parsed_params = parse_invoice_params

    if @invoice.update_attributes(parsed_params)
      event = Event.new(:name=>'edited',:invoice=>@invoice,:user=>User.current)
      # associate last created audits to this event
      event.audits = @invoice.last_audits_without_event
      event.save
      flash[:notice] = l(:notice_successful_update)
      respond_to do |format|
        format.html {
          if params[:save_and_send]
            if @invoice.valid?
              if ExportChannels[@invoice.client.invoice_format]['javascript']
                # channel sends via javascript, set autocall and autocall_args
                # 'show' action will set a div to tell javascript to automatically
                # call this function
                js = ExportChannels[@invoice.client.invoice_format]['javascript'].
                  gsub(':id',@invoice.id.to_s).gsub(/'/,"").split(/\(|\)/)
                redirect_to :action => 'show', :id => @invoice,
                  :autocall => js[0].html_safe, :autocall_args => js[1]
              else
                redirect_to :action => 'send_invoice', :id => @invoice
              end
            else
              flash[:error] = l(:errors_prevented_invoice_sent)
              redirect_to :action => 'show', :id => @invoice
            end
          else
            redirect_to :action => 'show', :id => @invoice
          end
        }
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render :action => "edit" }
        format.api { render_validation_errors(@invoice) }
      end
    end
  end

  def destroy
    @invoices.each do |invoice|
      begin
        invoice.reload.destroy
        event = EventDestroy.new(:name    => "deleted_#{invoice.type.underscore}",
                                 :notes   => invoice.number,
                                 :project => invoice.project)
        event.audits = invoice.last_audits_without_event
        event.save!
      rescue ::ActiveRecord::RecordNotFound # raised by #reload if invoice no longer exists
        # nothing to do, invoice was already deleted (eg. by a parent)
      end
    end
      respond_to do |format|
        format.html { redirect_back_or_default(:action => 'index', :project_id => @project, :back_url => params[:back_url]) }
        format.api  { render_api_ok }
      end
  end

  def destroy_payment
    @payment.destroy
    redirect_to :action => 'show', :id => @invoice
  end

  def duplicate_invoice
    orig = InvoiceDocument.find(params[:id])
    @invoice = IssuedInvoice.new orig.attributes
    @invoice.number += "-dup"
    orig.invoice_lines.each do |il|
      l = InvoiceLine.new il.attributes
      il.taxes.each do |tax|
        l.taxes << Tax.new(:name=>tax.name,:percent=>tax.percent)
      end
      @invoice.invoice_lines << l
    end
    @client = @invoice.client
    render :action => "new"
  end

  def base64doc
    doc_format=params[:doc_format]
    if request.get?
      # send a base64 encoded document
      # this is used to sign invoices with a local certificate
      if doc_format == 'pdf'
        doc = Haltr::Pdf.generate(@invoice)
      else
        doc = Haltr::Xml.generate(@invoice, doc_format, true)
      end
      base64_file=Tempfile.new("invoice_#{@invoice.id}.base64","tmp")
      File.open(base64_file.path, 'w') do |f|
        f.write(Base64::encode64(doc))
      end
      if base64_file
        send_file(base64_file.path,
                  :filename => (doc_format == "pdf" ? @invoice.pdf_name : @invoice.xml_name),
                  :type => "text/plain",
                  :disposition => 'inline')
      else
        render :text => "Error in #{doc_format} creation"
      end
    else
      # queue a signed document
      if file_contents = params['document']
        logger.info "Invoice #{@invoice.id} #{file_contents[0..16]}(...) received"
        file = Tempfile.new "invoice_signed_#{@invoice.id}.#{doc_format == "pdf" ? "pdf" : "xml"}", "tmp"
        file.binmode
        # TODO hack the ' ' to '+' replacement
        # rails replaces '+' with ' '. we undo that.
        file.write Base64.decode64(file_contents.gsub(' ','+'))
        file.close
        @invoice.queue!
        Haltr::Sender.send_invoice(@invoice, User.current, true, file)
        logger.info "Invoice #{@invoice.id} #{file.path} queued"
        render :text => "Document sent. document = #{file}"
      else
        render :text => "Missing document"
      end
    end
  rescue StateMachine::InvalidTransition
    logger.info "Invoice #{@invoice.id}: #{l(:state_not_allowed_for_sending, state: l("state_#{@invoice.state}"))}"
    render text: l(:state_not_allowed_for_sending, state: l("state_#{@invoice.state}"))
  end

  def show
    @invoices_not_sent = InvoiceDocument.find(:all,:conditions => ["client_id = ? and state = 'new'",@client.id]).sort
    @invoices_sent = InvoiceDocument.find(:all,:conditions => ["client_id = ? and state = 'sent'",@client.id]).sort
    @invoices_closed = InvoiceDocument.find(:all,:conditions => ["client_id = ? and state = 'closed'",@client.id]).sort
    @js = ExportChannels[@client.invoice_format]['javascript'] rescue nil
    @autocall = params[:autocall]
    @autocall_args = params[:autocall_args]
    @format = params["format"]
    respond_to do |format|
      format.html
      format.api do
        # Force "json" if format is emtpy
        # Used in refresher.js to check invoice status
        params[:format] ||= 'json'
      end
      format.pdf do
        @is_pdf = true
        @debug = params[:debug]
        render :pdf => @invoice.pdf_name_without_extension,
          :disposition => params[:view] ? 'inline' : 'attachment',
          :layout => "invoice.html",
          :template=>"invoices/show_pdf",
          :formats => :html,
          :show_as_html => params[:debug],
          :margin => {
            :top    => 20,
            :bottom => 20,
            :left   => 30,
            :right  => 20
          }
      end
      if params[:debug]
        format.facturae30  { render_xml Haltr::Xml.generate(@invoice, 'facturae30', false, false, true) }
        format.facturae31  { render_xml Haltr::Xml.generate(@invoice, 'facturae31', false, false, true) }
        format.facturae32  { render_xml Haltr::Xml.generate(@invoice, 'facturae32', false, false, true) }
        format.peppolubl20 { render_xml Haltr::Xml.generate(@invoice, 'peppolubl20', false, false, true) }
        format.peppolubl21 { render_xml Haltr::Xml.generate(@invoice, 'peppolubl21', false, false, true) }
        format.biiubl20    { render_xml Haltr::Xml.generate(@invoice, 'biiubl20', false, false, true) }
        format.svefaktura  { render_xml Haltr::Xml.generate(@invoice, 'svefaktura', false, false, true) }
        format.oioubl20    { render_xml Haltr::Xml.generate(@invoice, 'oioubl20', false, false, true) }
        format.efffubl     { render_xml Haltr::Xml.generate(@invoice, 'efffubl', false, false, true) }
        format.original    { render_xml @invoice.original }
      else
        format.facturae30  { download_xml Haltr::Xml.generate(@invoice, 'facturae30', false, false, true) }
        format.facturae31  { download_xml Haltr::Xml.generate(@invoice, 'facturae31', false, false, true) }
        format.facturae32  { download_xml Haltr::Xml.generate(@invoice, 'facturae32', false, false, true) }
        format.peppolubl20 { download_xml Haltr::Xml.generate(@invoice, 'peppolubl20', false, false, true) }
        format.peppolubl21 { download_xml Haltr::Xml.generate(@invoice, 'peppolubl21', false, false, true) }
        format.biiubl20    { download_xml Haltr::Xml.generate(@invoice, 'biiubl20', false, false, true) }
        format.svefaktura  { download_xml Haltr::Xml.generate(@invoice, 'svefaktura', false, false, true) }
        format.oioubl20    { download_xml Haltr::Xml.generate(@invoice, 'oioubl20', false, false, true) }
        format.efffubl     { download_xml Haltr::Xml.generate(@invoice, 'efffubl', false, false, true) }
        format.original    { download_xml @invoice.original }
      end
    end
  end

  def render_xml(xml)
    render :text => xml
  end

  def download_xml(xml)
    send_data xml,
      :type => 'text/xml; charset=UTF-8;',
      :disposition => "attachment; filename=#{@invoice.pdf_name_without_extension}.xml"
  end

  def show_original
    case @invoice.original
    when /<SchemaVersion>3\.2<\/SchemaVersion>/
      template = 'invoices/visor_face_32.xsl.erb'
    when /<SchemaVersion>3\.2\.1<\/SchemaVersion>/
      template = 'invoices/visor_face_321.xsl.erb'
    else
      redirect_to action: 'show', id: @invoice
      return
    end
    @is_pdf = (params[:format] == 'pdf')
    @invoices_not_sent = InvoiceDocument.find(:all,:conditions => ["client_id = ? and state = 'new'",@client.id]).sort
    @invoices_sent = InvoiceDocument.find(:all,:conditions => ["client_id = ? and state = 'sent'",@client.id]).sort
    @invoices_closed = InvoiceDocument.find(:all,:conditions => ["client_id = ? and state = 'closed'",@client.id]).sort
    @js = ExportChannels[@client.invoice_format]['javascript'] rescue nil
    @autocall = params[:autocall]
    @autocall_args = params[:autocall_args]
    @format = params["format"]
    doc   = Nokogiri::XML(@invoice.original)
    xslt  = Nokogiri::XSLT(render_to_string(:template=>template,:layout=>false))
    @out  = xslt.transform(doc)
    respond_to do |format|
      format.html do
        render :template => 'invoices/show_with_xsl'
      end
      format.pdf do
        @debug = params[:debug]
        render :pdf => @invoice.pdf_name_without_extension,
          :disposition => 'attachment',
          :layout => "invoice.html",
          :template=>"invoices/show_with_xsl",
          :formats => :html,
          :show_as_html => params[:debug],
          :margin => {:top => 20,
            :bottom => 20,
            :left   => 30,
            :right  => 20}
      end
    end
  end

  def send_invoice
    unless @invoice.valid?
      raise @invoice.errors.full_messages.join(', ')
    end
    unless ExportChannels.can_send? @invoice.client.invoice_format
      raise "#{l(:export_channel)}: #{ExportChannels.l(@invoice.client.invoice_format)}"
    end
    @invoice.queue!
    Haltr::Sender.send_invoice(@invoice, User.current)
    flash[:notice] = "#{l(:notice_invoice_sent)}"
  rescue StateMachine::InvalidTransition => e
    flash[:error] = l(:state_not_allowed_for_sending, state: l("state_#{@invoice.state}"))
  rescue Exception => e
    # e.backtrace does not fit in session leading to
    #   ActionController::Session::CookieStore::CookieOverflow
    msg = "#{l(:error_invoice_not_sent, :num=>@invoice.number)}: #{e.message}"
    flash[:error] = msg
    EventError.create(
      user:    User.current,
      invoice: @invoice,
      name:    'error_sending',
      notes:   msg
    )
    HiddenEvent.create(:name      => "error",
                       :invoice   => @invoice,
                       :error     => e.message,
                       :backtrace => e.backtrace)
    logger.info e
    logger.info e.backtrace
    #raise e if Rails.env == "development"
  ensure
    redirect_back_or_default(:action => 'show', :id => @invoice)
  end

  def send_new_invoices
    @invoices = IssuedInvoice.find_can_be_sent(@project)
    bulk_send
    render action: 'bulk_send'
  end

  def download_new_invoices
    require 'zip/zip'
    require 'zip/zipfilesystem'
    @company = @project.company
    invoices = IssuedInvoice.find_not_sent @project
    # just a safe big limit
    if invoices.size > 100
      flash[:error] = l(:too_much_invoices,:num=>invoices.size)
      redirect_to :action=>'index', :project_id=>@project
      return
    end
    zip_file = Tempfile.new "#{@project.identifier}_invoices.zip", 'tmp'
    logger.info "Creating zip file '#{zip_file.path}' for invoice ids #{invoices.collect{|i|i.id}.join(',')}."
    Zip::ZipOutputStream.open(zip_file.path) do |zos|
      invoices.each do |invoice|
        @invoice = invoice
        @lines = @invoice.invoice_lines
        @client = @invoice.client
        pdf_file = Haltr::Pdf.generate(@invoice, true)
        zos.put_next_entry(@invoice.pdf_name)
        zos << IO.binread(pdf_file.path)
        logger.info "Added #{@invoice.pdf_name} from #{pdf_file.path}"
      end
    end
    zip_file.close
    send_file zip_file.path, :type => "application/zip", :filename => "#{@project.identifier}-invoices.zip"
  rescue LoadError
    flash[:error] = l(:zip_gem_required)
    redirect_to :action => 'index', :project_id => @project
  end

  # Renders a partial to update curreny, payment_method, and invoice_terms
  # into an invoice form (ajax)
  def update_payment_stuff
    @client = Client.find(params[:invoice][:client_id]) unless !params[:invoice] or params[:invoice][:client_id].blank?
    @invoice = Invoice.find(params[:invoice_id]) rescue nil
    selected = @client.nil? ? params[:curr_sel] : @client.currency
    if params[:required] == "false"
      render :partial => "received/currency", :locals => {:selected=>selected}
    else
      render :partial => "payment_stuff", :locals => {:client=>@client}
    end
  end

  def by_taxcode_and_num
    taxcode = params[:taxcode]
    company = taxcode.blank? ? nil : Company.find_by_taxcode(taxcode)
    # patch for some spanish partners
    if company.nil? and !taxcode.blank?
      if taxcode =~ /^es/i
        company = Company.find_by_taxcode(taxcode.gsub(/^es/i,''))
      else
        company = Company.find_by_taxcode("ES#{taxcode}")
      end
    end
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

  # public view of invoice, without a session, using :find_hashid
  def view
    @last_success_sending_event = @invoice.last_success_sending_event
    @lines = @invoice.invoice_lines
    @invoices_not_sent = []
    @invoices_sent = IssuedInvoice.find(:all,:conditions => ["client_id = ? and state = 'sent'",@client.id]).sort
    @invoices_closed = IssuedInvoice.find(:all,:conditions => ["client_id = ? and state = 'closed'",@client.id]).sort
    unless @invoice.has_been_read or User.current.projects.include?(@invoice.project) or User.current.admin?
      Event.create!(:name=>'read',:invoice=>@invoice,:user=>User.current)
      @invoice.update_attribute(:has_been_read,true)
    end
    render :layout=>"public"
  rescue ActionView::MissingTemplate
    nil
  rescue Exception => e
    logger.debug e
    render_404
  end

  def logo
    if @attachment.image?
      send_file @attachment.diskfile, :filename => filename_for_content_disposition(@attachment.filename),
        :type => @attachment.content_type,
        :disposition => 'inline'
    else
      send_file  Rails.root.join("public/plugin_assets/haltr/images/transparent.gif"),
        :type => 'image/gif',
        :disposition => 'inline'
    end
  end

  # this is the same as download, but without the before filter :find_hashid
  def legal
    download
  end

  # downloads an invoice without login using client hash_id as credentials
  def download
    md5   = params[:md5]
    event = nil
    if params[:event]
      # event is @invoice.last_success_sending_event
      # used when downloading file from invoice client view
      event = @invoice.events.find(params[:event]) rescue nil
    end
    if event
      if event.is_a? EventWithFile
        send_data event.file, :filename => event.filename, :type => event.content_type
        return
      else
        md5 = event.md5
      end
    end
    # old way, external invoice storage
    if (Rails.env.development? or Rails.env.test?) and !Setting['plugin_haltr']['b2brouter_ip']
      logger.debug "This is a test XML invoice"
      send_file Rails.root.join("plugins/haltr/test/fixtures/xml/test_invoice_facturae32.xml")
    else
      if @invoice.fetch_from_backup(md5,params[:backup_name])
        respond_to do |format|
          format.html do
            send_data @invoice.legal_invoice,
              :type => @invoice.legal_content_type,
              :filename => @invoice.legal_filename,
              :disposition => params[:disposition] == 'inline' ? 'inline' : 'attachment'
          end
          format.xml do
            render :xml => @invoice.legal_invoice
          end
        end
      else
        flash[:warning]=l(:cant_connect_trace, "")
        render_404
      end
    end
  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH => e
    flash[:warning]=l(:cant_connect_trace, e.message)
    redirect_to :action => 'show', :id => @invoice
  end

  def amend_for_invoice
    amend = @invoice.create_amend
    redirect_to :action => 'edit', :id => amend
  end

  def mail
    invoice = InvoiceDocument.find(params[:id])
    if invoice.nil? or invoice.client.nil?
      render_404
    else
      respond_to do |format|
        format.html { render :text => invoice.recipient_emails.join(',') }
      end
    end
  end

  def report_invoice_list
    @from     = params[:date_from] || 3.months.ago
    @to       = params[:date_to]   || Date.today
    begin
      @from.to_date
    rescue
      flash[:error]="invalid date: #{@from}"
      @from = 3.months.ago
    end
    begin
      @to.to_date
    rescue
      flash[:error]="invalid date: #{@to}"
      @to = Date.today
    end
    invoices = @project.issued_invoices.includes(:client).where(
      ["date >= ? and date <= ? and amend_id is null", @from, @to]
    ).order(:number)
    invoices = invoices.where("date >= ?", @from).where("date <= ?", @to)

    @invoices = {}
    @total    = {}
    @taxes    = {}
    @tax_names = {}
    invoices.each do |i|
      @invoices[i.currency]  ||= []
      @invoices[i.currency]   << i
      @total[i.currency]     ||= Money.new(0,i.currency)
      @total[i.currency]      += i.subtotal
      @tax_names[i.currency] ||= i.tax_names
      @tax_names[i.currency]  += i.tax_names
      @tax_names[i.currency].uniq!
      i.taxes_uniq.each do |tax|
        @taxes[i.currency]           ||= {}
        @taxes[i.currency][tax.name] ||= Money.new(0,i.currency)
        @taxes[i.currency][tax.name]  += i.tax_amount(tax)
      end
    end
  end

  def report_channel_state
    @state_totals, @channel_totals, @channel_state_count, @total_count = Haltr::Report.channel_state(@project)
  end

  ### methods not reachable with any route:

  def invoice_class
    IssuedInvoice
  end

  def find_hashid
    @client = Client.find_by_hashid params[:client_hashid]
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
    @attachment = Attachment.find(params[:attachment_id])
    # Show 404 if the filename in the url is wrong
    raise ActiveRecord::RecordNotFound if params[:filename] && params[:filename] != @attachment.filename
    @project = @attachment.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_invoice
    @invoice = Invoice.find params[:id]
    @lines = @invoice.invoice_lines
    @client = @invoice.client || Client.new(:name=>"unknown",:project=>@invoice.project)
    @project = @invoice.project
    @company = @project.company
    if @invoice.client and @invoice.client.taxcode
      if @client.taxcode[0...2].downcase == @client.country
        taxcode2 = @client.taxcode[2..-1]
      else
        taxcode2 = "#{@client.country}#{@client.taxcode}"
      end
      @external_company = ExternalCompany.where('taxcode in (?, ?)', @client.taxcode, taxcode2).first
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_invoices
    @invoices = invoice_class.find_all_by_id(params[:id] || params[:ids])
    raise ActiveRecord::RecordNotFound if @invoices.empty?
    raise Unauthorized unless @invoices.collect {|i| i.project }.uniq.size == 1
    @project = @invoices.first.project
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

  def redirect_to_correct_controller
    if @invoice.is_a? IssuedInvoice and params[:controller] != "invoices"
      redirect_to(invoice_path(@invoice)) && return
    elsif @invoice.is_a? ReceivedInvoice and params[:controller] != "received"
      redirect_to(received_path(@invoice)) && return
    elsif @invoice.is_a? InvoiceTemplate and params[:controller] != "invoice_templates"
      redirect_to invoice_template_path(@invoice) && return
    end
  end

  # see redmine's context_menu controller
  def context_menu
    (render_404; return) unless @invoices.present?
    if (@invoices.size == 1)
      @invoice = @invoices.first
    end
    @invoice_ids = @invoices.map(&:id).sort

    @can = { :edit => User.current.allowed_to?(:general_use, @project),
             :read => (User.current.allowed_to?(:general_use, @project) ||
                      User.current.allowed_to?(:use_all_readonly, @project) ||
                      User.current.allowed_to?(:restricted_use, @project)),
             :bulk_download => User.current.allowed_to?(:bulk_download, @project)
           }
    @back = back_url

    render :layout => false
  end

  def bulk_download
    unless ExportFormats.available.keys.include? params[:in]
      flash[:error] = "unknown format #{params[:in]}"
      redirect_back_or_default(:action=>'index',:project_id=>@project.id)
      return
    end
    require 'zip/zip'
    require 'zip/zipfilesystem'
    # just a safe big limit
    if @invoices.size > 100
      flash[:error] = l(:too_much_invoices,:num=>@invoices.size)
      redirect_to :action=>'index', :project_id=>@project
      return
    end
    zip_file = Tempfile.new ["#{@project.identifier}_invoices", ".zip"], 'tmp'
    logger.info "Creating zip file '#{zip_file.path}' for invoice ids #{@invoices.collect{|i|i.id}.join(',')}."
    Zip::ZipOutputStream.open(zip_file.path) do |zos|
      @invoices.each do |invoice|
        @invoice = invoice
        @lines = @invoice.invoice_lines
        @client = @invoice.client
        file_name = @invoice.pdf_name_without_extension
        file_name += (params[:in] == "pdf" ? ".pdf" : ".xml")
        zos.put_next_entry(file_name)
        if params[:in] == "pdf"
          zos.print Haltr::Pdf.generate(@invoice)
        else
          zos.print Haltr::Xml.generate(@invoice,params[:in])
        end
        logger.info "Added #{file_name}"
      end
    end
    zip_file.close
    send_file zip_file.path, :type => "application/zip", :filename => "#{@project.identifier}-invoices.zip"
  rescue LoadError
    flash[:error] = l(:zip_gem_required)
    redirect_to :action => 'index', :project_id => @project
  end

  def mark_as
    if %w(new sent accepted registered refused closed).include? params[:state]
      begin
        @invoice.send("mark_as_#{params[:state]}!")
      rescue StateMachine::InvalidTransition
        # mark_as_* raise this on invalid invoices
        @invoice.update_attribute(:state, params[:state])
        Event.create(
          name: "done_mark_as_#{params[:state]}",
          invoice: @invoice,
          user: User.current
        )
      end
    else
      flash[:error] = "unknown state #{params[:state]}"
    end
    redirect_to :back
  rescue ActionController::RedirectBackError
    render :text => "OK"
  end

  def bulk_mark_as
    all_changed = true
    if %w(new sent accepted registered refused closed).include? params[:state]
      @invoices.each do |i|
        next if i.state == params[:state]
        all_changed = i.send("mark_as_#{params[:state]}") && all_changed
      end
    else
      flash[:error] = "unknown state #{params[:state]}"
    end
    flash[:warn] = l(:some_states_not_changed) unless all_changed
    redirect_back_or_default(:action=>'index',:project_id=>@project.id)
  end

  def bulk_send
    @errors=[]
    num_invoices = @invoices.size
    @invoices.collect! do |invoice|
      if invoice.valid? and invoice.can_queue? and
          ExportChannels.can_send? invoice.client.invoice_format
        if ExportChannels[invoice.client.invoice_format]['javascript']
          @errors << "#{l(:error_invoice_not_sent, :num=>invoice.number)}: Must be processed individually (channel with javascript)"
          nil
        else
          invoice
        end
      else
        err = "#{l(:error_invoice_not_sent, :num=>invoice.number)}: "
        if !invoice.valid?
          err += invoice.errors.full_messages.join(', ')
        elsif !invoice.can_queue?
          err += l(:state_not_allowed_for_sending, state: l("state_#{invoice.state}"))
        else
          err += "#{l(:export_channel)}: #{ExportChannels.l(invoice.client.invoice_format)}"
        end
        @errors << err
        nil
      end
    end.compact!
    Delayed::Job.enqueue(Haltr::BulkSender.new(@invoices.collect { |i| i.id }, User.current))
    @num_sent = @invoices.size

    if @num_sent < num_invoices
      flash[:error] = l(:some_invoices_sent,:sent=>@num_sent,:total=>num_invoices)
    else
      flash[:notice] = l(:all_invoices_sent)
    end
  end

  def haltr_sign
    @debug = true if params[:debug]=='true'
    respond_to do |format|
      format.js  { render :action => 'haltr_sign' }
    end
  end

  # Used in API only - facturae in POST body
  def import_facturae
    # Make sure that API users get used to set this content type
    # as it won't trigger Rails' automatic parsing of the request body for parameters
    unless request.content_type == 'application/octet-stream'
      render :nothing => true, :status => 406
      return
    end

    begin
      @invoice = Invoice.create_from_xml(
        request.raw_post,
        User.current,
        Digest::MD5.hexdigest(request.raw_post),
        'api'
      )
      respond_to do |format|
        format.api {
          render action: 'show', status: :created, location: invoice_path(@invoice)
        }
      end
    rescue => e
      @error_messages = [e.to_s]
      render :template => 'common/error_messages.api', :status => :unprocessable_entity, :layout => nil
    end
  end

  # Used in form POST - facturae in multipart POST 'file' field
  def import
    params[:issued] ||= '1'
    if request.post?
      file = params[:file]
      @invoice = nil
      if file && file.size > 0
        md5 = `md5sum #{file.path} | cut -d" " -f1`.chomp
        user_or_company = User.current.admin? ? @project.company : User.current
        @invoice = Invoice.create_from_xml(
          file, user_or_company, md5,'uploaded',nil,
          params[:issued] == '1',
          params['keep_original'] != 'false',
          params['validate'] != 'false'
        )
      end
      if @invoice and ["true","1"].include?(params[:send_after_import])
        begin
          Haltr::Sender.send_invoice(@invoice, User.current)
          @invoice.queue
        rescue
        end
      end
      respond_to do |format|
        format.html {
          if @invoice
            redirect_to invoice_path(@invoice)
          else
            flash[:warning] = l(:notice_uploaded_file_not_found)
            redirect_to :action => 'import', :project_id => @project
          end
        }
        format.api {
          render action: 'show', status: :created, location: invoice_path(@invoice)
        }
      end
    end
  rescue
    respond_to do |format|
      format.html {
        flash[:error] = $!.message
        redirect_to :action => 'import', :project_id => @project
      }
      format.api {
        @error_messages = [$!.message]
        render :template => 'common/error_messages.api', :status => :unprocessable_entity, :layout => nil
      }
    end
  end

  def original
    if @invoice.invoice_format == 'pdf'
      send_data @invoice.original,
        :type => 'application/pdf',
        :filename => @invoice.pdf_name,
        :disposition => params[:disposition] == 'inline' ? 'inline' : 'attachment'
    else
      send_data @invoice.original,
        :type => 'text/xml; charset=UTF-8;',
        :disposition => "attachment; filename=#{@invoice.xml_name}"
    end
  end

  def number_to_id
    respond_to do |format|
      format.html {
        render text: @invoice.id
      }
      format.api {
        render action: 'show', status: 200, location: invoice_path(@invoice)
      }
    end
  end

  def find_invoice_by_number
    @project = User.current.project
    @invoice = @project.invoices.find_by_number(params[:number])
    if @invoice.nil?
      respond_to do |format|
        format.html {
          render_404
        }
        format.api {
          render_api_head 404
        }
      end
      return
    end
  end

  def add_comment
    @comment = Comment.new
    @comment.safe_attributes = params[:comment]
    @comment.author = User.current
    if @invoice.comments << @comment
      flash[:notice] = l(:label_comment_added)
    end

    redirect_to invoice_path(@invoice)
  end

  private

  def parse_invoice_params
    parsed_params = params[:invoice]
    parsed_params['invoice_lines_attributes'] ||= {}
    # accept invoice_lines_attributes = { '0' => {}, ... }
    # and    invoice_lines_attributes = [{}, ...]
    if params[:invoice]['invoice_lines_attributes'].is_a? Array
      parsed_params['invoice_lines_attributes'] = Hash[
        params[:invoice]['invoice_lines_attributes'].map.with_index do |il, i|
          [i, il]
        end
      ]
    end
    parsed_params['invoice_lines_attributes'].each do |i, invoice_line|
      invoice_line['taxes_attributes'] ||= {}
      # accept taxes_attributes = { '0' => {}, ... }
      # and    taxes_attributes = [{}, ...]
      if invoice_line['taxes_attributes'].is_a? Array
        invoice_line['taxes_attributes'] = Hash[
          invoice_line['taxes_attributes'].map.with_index do |tax, j|
            [j, tax]
          end
        ]
      end
      invoice_line['taxes_attributes'].each do |j, tax|
        if tax['code'].blank? and
            #TODO: this condition allows to create taxes without knowing the
            # tax code (usefull from API) but when you edit invoice, tax is
            # not selected correctly
            (tax['percent'].blank? or tax['name'].blank?)
          tax['_destroy'] = 1
        end
        if tax['code'] =~ /_E|_NS$/
          tax['comment'] = params["#{tax['name']}_comment"]
        else
          tax['comment'] = ''
        end
      end
    end
    parsed_params
  end

end
