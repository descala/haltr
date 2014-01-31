class InvoicesController < ApplicationController

  unloadable
  menu_item Haltr::MenuItem.new(:invoices,:invoices_level2)
  menu_item Haltr::MenuItem.new(:invoices,:reports), :only => :report
  menu_item Haltr::MenuItem.new(:invoices,:import), :only => :import
  helper :haltr
  helper :context_menus
  layout 'haltr'

  helper :sort
  include SortHelper

  PUBLIC_METHODS = [:by_taxcode_and_num,:view,:download,:mail,:logo,:haltr_sign]

  before_filter :find_project_by_project_id, :only => [:index,:new,:create,:send_new_invoices,:download_new_invoices,:update_payment_stuff,:new_invoices_from_template,:report,:create_invoices,:update_taxes,:import]
  before_filter :find_invoice, :only => [:edit,:update,:mark_sent,:mark_closed,:mark_not_sent,:mark_accepted_with_mail,:mark_accepted,:mark_refused_with_mail,:mark_refused,:duplicate_invoice,:base64doc,:show,:send_invoice,:legal,:amend_for_invoice,:original,:validate,:show_original]
  before_filter :find_invoices, :only => [:context_menu,:bulk_download,:bulk_mark_as,:bulk_send,:destroy,:bulk_validate]
  before_filter :find_payment, :only => [:destroy_payment]
  before_filter :find_hashid, :only => [:view,:download]
  before_filter :find_attachment, :only => [:logo]
  before_filter :set_iso_countries_language
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

  def index
    sort_init 'invoices.created_at', 'desc'
    sort_update %w(invoices.created_at state number date due_date clients.name import_in_cents)

    invoices = @project.invoices.scoped.where("type = ?","IssuedInvoice")

    unless params["state_all"] == "1"
      statelist=[]
      %w(new sending sent error closed discarded).each do |state|
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

  def new
    @client = Client.find(params[:client]) if params[:client]
    @client ||= Client.find(:all, :order => 'name', :conditions => ["project_id = ?", @project]).first
    @client ||= Client.new
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

    @invoice = invoice_class.new(parsed_params)
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
        if @invoice.can_be_exported?
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
    else
      logger.info "Invoice errors #{@invoice.errors.full_messages}"
      render :action => "new"
    end
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
        if @invoice.can_be_exported?
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
    else
      render :action => "edit"
    end
  end

  def destroy
    @invoices.each do |invoice|
      begin
        invoice.reload.destroy
      rescue ::ActiveRecord::RecordNotFound # raised by #reload if invoice no longer exists
        # nothing to do, invoice was already deleted (eg. by a parent)
      end
    end
    redirect_back_or_default(:action => 'index', :project_id => @project, :back_url => params[:back_url])
  end

  def destroy_payment
    @payment.destroy
    redirect_to :action => 'show', :id => @invoice
  end

  def mark_sent
    @invoice.manual_send
    redirect_to :back
  rescue ActionController::RedirectBackError
    render :text => "OK"
  end

  def mark_closed
    @invoice.close
    redirect_to :back
  rescue ActionController::RedirectBackError
    render :text => "OK"
  end

  def mark_not_sent
    @invoice.mark_unsent
    redirect_to :back
  rescue ActionController::RedirectBackError
    render :text => "OK"
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
      # send a base64 encoded pdf document
      # this is used to sign invoices with a local certificate
      @local_certificate = true
      file = doc_format == "pdf" ? create_pdf_file : create_xml_file(doc_format)
      base64_file=Tempfile.new("invoice_#{@invoice.id}.base64","tmp")
      File.open(base64_file.path, 'w') do |f|
        f.write(Base64::encode64(File.read(file.path)))
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
      # queue a signed pdf document
      if file_contents = params['document']
        logger.info "Invoice #{@invoice.id} #{file_contents[0..16]}(...) received"
        file = Tempfile.new "invoice_signed_#{@invoice.id}.#{doc_format == "pdf" ? "pdf" : "xml"}", "tmp"
        file.binmode
        # TODO hack the ' ' to '+' replacement
        # rails replaces '+' with ' '. we undo that.
        file.write Base64.decode64(file_contents.gsub(' ','+'))
        file.close
        queue_file file
        logger.info "Invoice #{@invoice.id} #{file.path} queued"
        render :text => "Document sent. document = #{file}"
      else
        render :text => "Missing document"
      end
    end
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
      format.pdf do
        @is_pdf = true
        render :pdf => @invoice.pdf_name_without_extension,
          :disposition => 'attachment',
          :layout => "invoice.html",
          :template=>"invoices/show_pdf",
          :formats => :html,
          :show_as_html => params[:debug]
      end
      if params[:debug]
        format.facturae30  { render_clean_xml :formats => :xml, :template => 'invoices/facturae30',  :layout => false }
        format.facturae31  { render_clean_xml :formats => :xml, :template => 'invoices/facturae31',  :layout => false }
        format.facturae32  { render_clean_xml :formats => :xml, :template => 'invoices/facturae32',  :layout => false }
        format.peppolubl20 { render_clean_xml :formats => :xml, :template => 'invoices/peppolubl20', :layout => false }
        format.biiubl20    { render_clean_xml :formats => :xml, :template => 'invoices/biiubl20',    :layout => false }
        format.svefaktura  { render_clean_xml :formats => :xml, :template => 'invoices/svefaktura',  :layout => false }
        format.oioubl20    { render_clean_xml :formats => :xml, :template => 'invoices/oioubl20',    :layout => false }
        format.efffubl     { add_efffubl_base64_pdf; render_clean_xml :formats => :xml, :template => 'invoices/efffubl',    :layout => false }
      else
        format.facturae30  { download_clean_xml :formats => :xml, :template => 'invoices/facturae30',  :layout => false }
        format.facturae31  { download_clean_xml :formats => :xml, :template => 'invoices/facturae31',  :layout => false }
        format.facturae32  { download_clean_xml :formats => :xml, :template => 'invoices/facturae32',  :layout => false }
        format.peppolubl20 { download_clean_xml :formats => :xml, :template => 'invoices/peppolubl20', :layout => false }
        format.biiubl20    { download_clean_xml :formats => :xml, :template => 'invoices/biiubl20',    :layout => false }
        format.svefaktura  { download_clean_xml :formats => :xml, :template => 'invoices/svefaktura',  :layout => false }
        format.oioubl20    { download_clean_xml :formats => :xml, :template => 'invoices/oioubl20',    :layout => false }
        format.efffubl     { add_efffubl_base64_pdf; download_clean_xml :formats => :xml, :template => 'invoices/efffubl',    :layout => false }
      end
    end
  end

  def show_original
    @invoice.update_attribute(:has_been_read, true) if @invoice.is_a? ReceivedInvoice
    if @invoice.invoice_format == "pdf"
      render :template => 'received/show_pdf'
    else
      doc  = Nokogiri::XML(@invoice.original)
      # TODO: received/facturae31.xsl.erb and received/facturae30.xsl.erb templates
      xslt = Nokogiri::XSLT(render_to_string(:template=>'received/facturae32.xsl.erb',:layout=>false))
      @out  = xslt.transform(doc)
      render :template => 'received/show_with_xsl'
    end
  end

  def send_invoice
    create_and_queue_file
    flash[:notice] = "#{l(:notice_invoice_sent)}"
  rescue Exception => e
    # e.backtrace does not fit in session leading to
    #   ActionController::Session::CookieStore::CookieOverflow
    flash[:error] = "#{l(:error_invoice_not_sent, :num=>@invoice.number)}: #{e.message}"
    #raise e if Rails.env == "development"
  ensure
    redirect_back_or_default(:action => 'show', :id => @invoice)
  end

  def send_new_invoices
    num = 0
    @errors=[]
    IssuedInvoice.find_can_be_sent(@project).each do |inv|
      if num >= 10
        flash[:error] = l(:invoice_limit_reached)
        break
      end
      @invoice = inv
      @lines = @invoice.invoice_lines
      @client = @invoice.client || Client.new(:name=>"unknown",:project=>@invoice.project)
      @company = @project.company
      begin
        create_and_queue_file
        num = num + 1
      rescue Exception => e
        @errors << "#{l(:error_invoice_not_sent, :num=>@invoice.number)}: #{e.message}"
      end
    end
    @num_sent = num
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
        pdf_file = create_pdf_file
        zos.put_next_entry(@invoice.pdf_name)
        zos.print IO.read(pdf_file.path)
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
    @client = Client.find(params[:invoice][:client_id]) unless params[:invoice][:client_id].blank?
    selected = @client.nil? ? params[:curr_sel] : @client.currency
    if params[:required] == "false"
      render :partial => "received/currency", :locals => {:selected=>selected}
    else
      render :partial => "payment_stuff", :locals => {:client=>@client}
    end
  end

  def by_taxcode_and_num
    company = params[:taxcode].blank? ? nil : Company.find_by_taxcode(params[:taxcode])
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

  # this is the same as download, but without the befor filter :find_hashid
  def legal
    download
  end

  # downloads an invoice without login using its hash_id and its md5 as credentials
  def download
    if (Rails.env.development? or Rails.env.test?) and !Setting['plugin_haltr']['b2brouter_ip']
      logger.debug "This is a test XML invoice"
      send_file Rails.root.join("plugins/haltr/test/fixtures/xml/test_invoice_facturae32.xml")
    else
      #TODO: several B2bRouters
      if @invoice.fetch_from_backup(params[:md5],params[:backup_name])
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

  def report
    m = params[:months_ago] || 3
    d = Date.today - m.to_i.months
    @date = Date.new(d.year,d.month,1)
    @invoices = {}
    @total    = {}
    @taxes    = {}
    @tax_names = {}
    IssuedInvoice.all(:include => [:client],
                      :conditions => ["clients.project_id = ? and date >= ? and amend_id is null", @project.id, @date],
                      :order => :number
    ).each do |i|
      @invoices[i.currency] ||= []
      @invoices[i.currency] << i
      @total[i.currency]    ||= Money.new(0,i.currency)
      @total[i.currency]     += i.subtotal
      @tax_names[i.currency] ||= i.tax_names
      @tax_names[i.currency] += i.tax_names
      @tax_names[i.currency].uniq!
      i.taxes_uniq.each do |tax|
        @taxes[i.currency] ||= {}
        @taxes[i.currency][tax.name]  ||= Money.new(0,i.currency)
        @taxes[i.currency][tax.name]  += i.tax_amount(tax)
      end
    end
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
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_invoices
    @invoices = Invoice.find_all_by_id(params[:id] || params[:ids])
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

  def create_pdf_file
    @is_pdf = true
    pdf = render_to_string :pdf => @invoice.pdf_name_without_extension,
      :layout   => "invoice.html",
      :template => 'invoices/show_pdf',
      :formats  => :html
    pdf_file = Tempfile.new(@invoice.pdf_name,:encoding => 'ascii-8bit')
    pdf_file.write pdf
    logger.info "Created PDF #{pdf_file.path}"
    pdf_file.close
    return pdf_file
  end

  def create_xml_file(format)
    add_efffubl_base64_pdf if format == 'efffubl'
    # if it is an imported invoice, has not been modified and
    # invoice format  matches client format, send original file
    if @invoice.original and !@invoice.modified_since_created? and format == @invoice.invoice_format
      xml = @invoice.original
    else
      xml = render_to_string(:template => "invoices/#{format}",
                             :formats => :xml, :layout => false)
    end
    xml_file = Tempfile.new("invoice_#{@invoice.id}.xml")
    xml_file.write(clean_xml(xml))
    logger.info "Created XML #{xml_file.path}"
    xml_file.close
    return xml_file
  end

  def create_and_queue_file
    raise @invoice.export_errors.collect {|e| l(e)}.join(", ") unless @invoice.can_be_exported?
    export_id = @invoice.client.invoice_format
    @format = ExportChannels.format export_id
    @company = @project.company
    invoice_file = @format == 'pdf' ? create_pdf_file : create_xml_file(@format)
    if ExportChannels.folder(export_id).nil?
      # call invoice method
      method = ExportChannels.call_invoice_method(export_id)
      if method and @invoice.respond_to?(method)
        @invoice.send(method, invoice_file.path, ExportChannels[export_id])
      end
    else
      # store file in a folder (queue)
      queue_file(invoice_file)
    end
  end

  def queue_file(invoice_file)
    export_id = @invoice.client.invoice_format
    path = ExportChannels.path export_id
    format = ExportChannels.format export_id
    file_ext = format == "pdf" ? "pdf" : "xml"
    i=2
    destination="#{path}/" + "#{@invoice.client.hashid}_#{@invoice.id}.#{file_ext}".gsub(/\//,'')
    while File.exists? destination
      destination="#{path}/" + "#{@invoice.client.hashid}_#{i}_#{@invoice.id}.#{file_ext}".gsub(/\//,'')
      i+=1
    end
    logger.info "Sending #{format} to '#{destination}' for invoice id #{@invoice.id}."
    if Rails.env == "development"
      FileUtils.cp(invoice_file.path,'./queued_file.data')
    end
    FileUtils.mv(invoice_file.path,destination)
    #TODO state restrictions
    @invoice.queue || @invoice.requeue
  end

  def render_clean_xml(options)
    xml = render_to_string(options)
    render :text => clean_xml(xml)
  end

  def download_clean_xml(options)
    xml = render_to_string(options)
    send_data clean_xml(xml),
    :type => 'text/xml; charset=UTF-8;',
    :disposition => "attachment; filename=#{@invoice.pdf_name_without_extension}.xml"
  end

  def clean_xml(xml)
    xsl =<<XSL
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
  <xsl:strip-space elements="*"/>
  <xsl:template match="/">
    <xsl:copy-of select="."/>
  </xsl:template>
</xsl:stylesheet>
XSL
    doc  = Nokogiri::XML(xml)
    xslt = Nokogiri::XSLT(xsl)
    out  = xslt.transform(doc)
    out.to_xml
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
                      User.current.allowed_to?(:use_all_readonly, @project)),
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
    zip_file = Tempfile.new "#{@project.identifier}_invoices.zip", 'tmp'
    logger.info "Creating zip file '#{zip_file.path}' for invoice ids #{@invoices.collect{|i|i.id}.join(',')}."
    Zip::ZipOutputStream.open(zip_file.path) do |zos|
      @invoices.each do |invoice|
        @invoice = invoice
        @lines = @invoice.invoice_lines
        @client = @invoice.client
        file_name = @invoice.pdf_name_without_extension
        case params[:in]
        when "pdf"
          file = create_pdf_file
          file_name += ".pdf"
        else
          file = create_xml_file(params[:in])
          file_name += ".xml"
        end
        zos.put_next_entry(file_name)
        zos.print IO.read(file.path)
        logger.info "Added #{file_name} from #{file.path}"
      end
    end
    zip_file.close
    send_file zip_file.path, :type => "application/zip", :filename => "#{@project.identifier}-invoices.zip"
  rescue LoadError
    flash[:error] = l(:zip_gem_required)
    redirect_to :action => 'index', :project_id => @project
  end

  def bulk_mark_as
    all_changed = true
    @invoices.each do |i|
      next if i.state == params[:state]
      case params[:state]
      when "new"
        all_changed &&= (i.mark_unsent)
      when "sent"
        all_changed &&= (i.manual_send || i.success_sending || i.unpaid)
      when "closed"
        all_changed &&= (i.close || i.paid)
      else
        flash[:error] = "unknown state #{params[:state]}"
      end
    end
    flash[:warn] = l(:some_states_not_changed) unless all_changed
    redirect_back_or_default(:action=>'index',:project_id=>@project.id)
  end

  def bulk_send
    sent = 0
    errors = {}
    @invoices.each do |invoice|
      @invoice = invoice
      @lines = @invoice.invoice_lines
      @client = @invoice.client || Client.new(:name=>"unknown",:project=>@invoice.project)
      @company = @project.company
      begin
        if ExportChannels[@invoice.client.invoice_format]['javascript']
          raise Exception.new("Must be processed individually (channel with javascript)")
        end
        create_and_queue_file
        sent += 1
      rescue Exception => e
        errors[@invoice.number] = e.message
      end
    end
    if sent < @invoices.size
      if Rails.env.development?
        flash[:error] = l(:some_invoices_sent,:sent=>sent,:total=>@invoices.size) +
          errors.collect {|num, err| "#{num}: #{err}" }.join(", ")
      else
        flash[:error] = l(:some_invoices_sent,:sent=>sent,:total=>@invoices.size)
      end
    else
      flash[:notice] = l(:all_invoices_sent)
    end
    redirect_back_or_default(:action => 'index', :project_id => @project.id)
  end

  def haltr_sign
    respond_to do |format|
      format.js  { render :action => 'haltr_sign' }
    end
  end

  def add_efffubl_base64_pdf
    file = create_pdf_file
    @efffubl_base64_pdf = Base64::encode64(File.read(file.path))
  end

  def import
    if request.post?
      file = params[:file]
      if file && file.size > 0
        md5 = `md5sum #{file.path} | cut -d" " -f1`.chomp
        invoice = Invoice.create_from_xml(file,@project.company,User.current.name,md5,'uploaded')
        redirect_to invoice_path(invoice)
      else
        flash[:warning] = l(:notice_uploaded_file_not_found)
        redirect_to :action => 'import', :project_id => @project
      end
    end
  rescue
    flash[:error] = $!.message
    redirect_to :action => 'import', :project_id => @project
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

end
