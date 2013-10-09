class InvoicesController < ApplicationController

  unloadable
  menu_item Haltr::MenuItem.new(:invoices,:invoices_level2)
  menu_item Haltr::MenuItem.new(:invoices,:reports), :only => :report
  helper :haltr
  layout 'haltr'

  helper :sort
  include SortHelper

  before_filter :find_project_by_project_id, :only => [:index,:new,:create,:send_new_invoices, :download_new_invoices, :update_payment_stuff,:new_invoices_from_template,:create_invoices,:report,:update_taxes]
  before_filter :find_invoice, :only => [:edit,:update,:destroy,:mark_sent,:mark_closed,:mark_not_sent,:mark_accepted_with_mail,:mark_accepted,:mark_refused_with_mail,:mark_refused,:duplicate_invoice,:pdfbase64,:show,:send_invoice,:legal,:amend_for_invoice] 
  before_filter :find_payment, :only => [:destroy_payment]
  before_filter :find_hashid, :only => [:view,:download]
  before_filter :find_attachment, :only => [:logo]
  before_filter :set_iso_countries_language
  before_filter :authorize, :except => [:by_taxcode_and_num,:view,:download,:mail]
  skip_before_filter :check_if_login_required, :only => [:by_taxcode_and_num,:view,:download,:mail]
  # on development skip auth so we can use curl to debug
  if Rails.env.development? or Rails.env.test?
    skip_before_filter :check_if_login_required, :only => [:by_taxcode_and_num,:view,:download,:mail,:show]
    skip_before_filter :authorize, :only => [:show]
  else
    before_filter :check_remote_ip, :only => [:by_taxcode_and_num,:mail]
  end
  before_filter :redirect_to_correct_controller, :only => [:show]

  include CompanyFilter
  before_filter :check_for_company, :except => [:by_taxcode_and_num,:view,:download,:mail]

  skip_before_filter :verify_authenticity_token, :only => [:pdfbase64]

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

    @unread = invoices.where("type = ? AND has_been_read = ?", 'ReceivedInvoice', false).count
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
        redirect_to :action => 'send_invoice', :id => @invoice
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
        redirect_to :action => 'send_invoice', :id => @invoice
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

  def pdfbase64
    if request.get?
      # send a base64 encoded pdf document
      pdf_file = create_pdf_file
      base64_file=Tempfile.new("invoice_#{@invoice.id}.pdf.base64","tmp")
      File.open(base64_file.path, 'w') do |f|
        f.write(Base64::encode64(File.read(pdf_file.path)))
      end
      if base64_file
        send_file(base64_file.path, :filename => @invoice.pdf_name, :type => "text/plain", :disposition => 'inline')
      else
        render :text => "Error in PDF creation"
      end
    else
      # queue a signed pdf document
      if file_contents = params['document']
        logger.info "Invoice #{@invoice.id} #{file_contents[0..16]}(...) received"
        file = Tempfile.new "invoice_signed_#{@invoice.id}.pdf", "tmp"
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
      format.facturae30  { render_clean_xml :formats => :xml, :template => 'invoices/facturae30',  :layout => false }
      format.facturae31  { render_clean_xml :formats => :xml, :template => 'invoices/facturae31',  :layout => false }
      format.facturae32  { render_clean_xml :formats => :xml, :template => 'invoices/facturae32',  :layout => false }
      format.peppolubl20 { render_clean_xml :formats => :xml, :template => 'invoices/peppolubl20', :layout => false }
      format.biiubl20    { render_clean_xml :formats => :xml, :template => 'invoices/biiubl20',    :layout => false }
      format.svefaktura  { render_clean_xml :formats => :xml, :template => 'invoices/svefaktura',  :layout => false }
      format.oioubl20    { render_clean_xml :formats => :xml, :template => 'invoices/oioubl20',    :layout => false }
    end
  end

  def send_invoice
    create_and_queue_file
    flash[:notice] = "#{l(:notice_invoice_sent)}"
  rescue Exception => e
    # e.backtrace does not fit in session leading to
    #   ActionController::Session::CookieStore::CookieOverflow
    flash[:error] = "#{l(:error_invoice_not_sent, :num=>@invoice.number)}: #{e.message}"
    raise e if Rails.env == "development"
  ensure
    redirect_to :action => 'show', :id => @invoice
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
        pdf_file.close
        logger.info "Added #{@invoice.pdf_name} from #{pdf_file.path}"
      end
    end
    send_file zip_file.path, :type => "application/zip", :filename => "#{@project.identifier}-invoices.zip"
    zip_file.close
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

  # public view of invoice, without a session, using :find_hashid
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
            send_data @invoice.legal_invoice, :filename => @invoice.legal_filename
          end
          format.xml do
            render :xml => @invoice.legal_invoice
          end
        end
      else
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
    curr_lang = I18n.locale
    I18n.locale = @invoice.client.language rescue curr_lang
    @is_pdf = true
    pdf = render_to_string :pdf => @invoice.pdf_name_without_extension, :layout => "invoice.html", :template=>'invoices/show_pdf'
    pdf_file = Tempfile.new(@invoice.pdf_name,:encoding => 'ascii-8bit')
    pdf_file.write pdf
    logger.info "Created PDF #{pdf_file.path}"
    I18n.locale = curr_lang
    return pdf_file
  end

  def create_and_queue_file
    raise @invoice.export_errors.collect {|e| l(e)}.join(", ") unless @invoice.can_be_exported?
    export_id = @invoice.client.invoice_format
    @format = ExportChannels.format export_id
    @company = @project.company
    file_ext = @format == "pdf" ? "pdf" : "xml"
    if @format == 'pdf'
      invoice_file = create_pdf_file
    else
      invoice_file=Tempfile.new("invoice_#{@invoice.id}.#{file_ext}","tmp")
      invoice_file.write(clean_xml(render_to_string(:template => "invoices/#{@format}.xml.erb", :layout => false)))
    end
    invoice_file.close
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

end
