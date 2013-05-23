class InvoicesController < ApplicationController

  unloadable
  menu_item :haltr_invoices
  helper :haltr
  layout 'haltr'

  helper :sort
  include SortHelper

  before_filter :find_invoice, :except => [:index,:new,:create,:destroy_payment,:update_currency_select,:by_taxcode_and_num,:view,:logo,:download,:mail,:send_new_invoices, :download_new_invoices]
  before_filter :find_project, :only => [:index,:new,:create,:update_currency_select,:send_new_invoices, :download_new_invoices]
  before_filter :find_payment, :only => [:destroy_payment]
  before_filter :find_hashid, :only => [:view,:download]
  before_filter :find_attachment, :only => [:logo]
  before_filter :set_iso_countries_language
  before_filter :authorize, :except => [:by_taxcode_and_num,:view,:logo,:download,:mail]
  skip_before_filter :check_if_login_required, :only => [:by_taxcode_and_num,:view,:logo,:download,:mail]
  # on development skip auth so we can use curl to debug
  if Rails.env.development? or Rails.env.test?
    skip_before_filter :check_if_login_required, :only => [:by_taxcode_and_num,:view,:logo,:download,:mail,:facturae30,:facturae31,:facturae32,:peppolubl20,:biiubl20,:svefaktura, :oioubl20]
    skip_before_filter :authorize, :only => [:facturae30,:facturae31,:facturae32,:peppolubl20,:biiubl20,:svefaktura,:oioubl20]
  else
    before_filter :check_remote_ip, :only => [:by_taxcode_and_num,:mail]
  end

  # TODO http://stackoverflow.com/questions/3707071/rails-2-to-rails-3-method-verification-in-controllers-gone 
  # verify :method => [:post,:put], :only => [:create,:update], :redirect_to => :root_path

  include CompanyFilter
  before_filter :check_for_company, :except => [:by_taxcode_and_num,:view,:download,:mail]

  skip_before_filter :verify_authenticity_token, :only => [:pdfbase64]

  def index
    sort_init 'invoices.created_at', 'desc'
    sort_update %w(invoices.created_at state number date due_date clients.name import_in_cents)

    invoices = @project.invoices.scoped :conditions => ["type != ?","DraftInvoice"]

    unless params["state_all"] == "1"
      statelist=[]
      %w(new sending sent error closed discarded).each do |state|
        if params[state] == "1"
          statelist << "'#{state}'"
        end
      end
      if statelist.any?
        invoices = invoices.scoped :conditions => ["state in (#{statelist.join(",")})"]
      end
    end

    # client filter
    # TODO: change view collection_select (doesnt display previously selected client)
    unless params[:client_id].blank?
      invoices = invoices.scoped :conditions => ["client_id = ?", params[:client_id]]
      @client_id = params[:client_id].to_i rescue nil
    end

    # date filter
    unless params[:date_from].blank?
      invoices = invoices.scoped :conditions => ["date >= ?",params[:date_from]]
    end
    unless params["date_to"].blank?
      invoices = invoices.scoped :conditions => ["date <= ?",params[:date_to]]
    end

    issued_invoices = invoices.scoped :conditions => ['type = ?', 'IssuedInvoice']

    @i_invoice_count = issued_invoices.count
    @i_invoice_pages = Paginator.new self, @i_invoice_count,
		per_page_option,
		params['i_page']
    @i_invoices =  issued_invoices.find :all,
       :order => sort_clause,
       :include => [:client],
       :limit  =>  @i_invoice_pages.items_per_page,
       :offset =>  @i_invoice_pages.current.offset

    received_invoices = invoices.scoped :conditions => ['type = ?', 'ReceivedInvoice']

    @r_invoice_count = received_invoices.count
    @r_invoice_pages = Paginator.new self, @r_invoice_count,
		per_page_option,
		params['r_page']
    @r_invoices =  received_invoices.find :all,
       :order => sort_clause,
       :include => [:client],
       :limit  =>  @r_invoice_pages.items_per_page,
       :offset =>  @r_invoice_pages.current.offset

    @unread = received_invoices.count :all, :conditions => ["has_been_read = ?", false]

  end

  def new
    @client = Client.find(params[:client]) if params[:client]
    @client ||= Client.find(:all, :order => 'name', :conditions => ["project_id = ?", @project]).first
    @client ||= Client.new
    @invoice = IssuedInvoice.new(:client=>@client,:project=>@project,:date=>Date.today,:number=>IssuedInvoice.next_number(@project))
    @invoice.currency = @client.currency
    il = InvoiceLine.new(:new_and_first=>true)
    @project.company.taxes.each do |tax|
      il.taxes << Tax.new(:name=>tax.name, :percent=>tax.percent) if tax.default
    end
    @invoice.invoice_lines << il
  end

  def edit
    @invoice = InvoiceDocument.find(params[:id])
  end

  def create
    # mark as "_destroy" all taxes with an empty tax code
    # and copy global "exempt comment" to all exempt taxes
    parsed_params = params[:invoice]
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
        # set currency from invoice on each line
        invoice_line['currency'] = params[:invoice][:currency]
      end
    end

    @invoice = IssuedInvoice.new(parsed_params)
    if @invoice.invoice_lines.empty?
      il = InvoiceLine.new(:new_and_first=>true)
      @project.company.taxes.each do |tax|
        il.taxes << Tax.new(:name=>tax.name, :percent=>tax.percent) if tax.default
      end
      @invoice.invoice_lines << il
    end
    @client = @invoice.client
    @invoice.project = @project
    if @invoice.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'show', :id => @invoice
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

  def mark_accepted_with_mail
    MailNotifier.deliver_received_invoice_accepted(@invoice,params[:reason])
    mark_accepted
  end

  def mark_accepted
    Event.create(:name=>'accept',:invoice=>@invoice,:user=>User.current,:info=>params[:reason])
    redirect_to :back
  rescue ActionController::RedirectBackError
    render :text => "OK"
  end

  def mark_refused_with_mail
    MailNotifier.deliver_received_invoice_refused(@invoice,params[:reason])
    mark_refused
  end

  def mark_refused
    Event.create(:name=>'refuse',:invoice=>@invoice,:user=>User.current,:info=>params[:reason])
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

  def pdf
    pdf_file = create_pdf_file
    if pdf_file
      send_file(pdf_file.path, :filename => @invoice.pdf_name, :type => "application/pdf", :disposition => 'inline')
    else
      render :text => "Error in PDF creation"
    end
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

  # methods to debugg xml
  def facturae30
    @format = "facturae30"
    @company = @invoice.company
    render_clean_xml :template => 'invoices/facturae30.xml.erb', :layout => false
  end
  def facturae31
    @format = "facturae31"
    @company = @invoice.company
    render_clean_xml :template => 'invoices/facturae31.xml.erb', :layout => false
  end
  def facturae32
    @format = "facturae32"
    @company = @invoice.company
    render_clean_xml :template => 'invoices/facturae32.xml.erb', :layout => false
  end
  def peppolubl20
    @company = @invoice.company
    render_clean_xml :template => 'invoices/peppolubl20.xml.erb', :layout => false
  end
  def biiubl20
    @company = @invoice.company
    render_clean_xml :template => 'invoices/biiubl20.xml.erb', :layout => false
  end
  def svefaktura
    @company = @invoice.company
    render_clean_xml :template => 'invoices/svefaktura.xml.erb', :layout => false
  end
  def oioubl20 
    @company = @invoice.company
    render_clean_xml :template => 'invoices/oioubl20.xml.erb', :layout => false
  end

  def show
    if @invoice.is_a? IssuedInvoice
      @invoices_not_sent = InvoiceDocument.find(:all,:conditions => ["client_id = ? and state = 'new'",@client.id]).sort
      @invoices_sent = InvoiceDocument.find(:all,:conditions => ["client_id = ? and state = 'sent'",@client.id]).sort
      @invoices_closed = InvoiceDocument.find(:all,:conditions => ["client_id = ? and state = 'closed'",@client.id]).sort
    elsif @invoice.is_a? ReceivedInvoice
      @invoice.update_attribute(:has_been_read, true)
      if @invoice.invoice_format == "pdf"
        render :template => 'received_invoices/show_pdf'
      else
        # TODO also show the database record version?
        # Redel XML with XSLT in browser
        @xsl = 'facturae32'
        render :template => 'received_invoices/show_with_xsl'
      end
    end
  end

  def send_invoice
    create_and_queue_file
    flash[:notice] = "#{l(:notice_invoice_sent)}"
  rescue Exception => e
    # e.backtrace does not fit in session leading to
    #   ActionController::Session::CookieStore::CookieOverflow
    flash[:error] = "#{l(:error_invoice_not_sent, :num=>@invoice.number)}: #{e.message}"
    raise e if RAILS_ENV == "development"
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
    @is_pdf = false  # Remove this global flag used in app/helpers/haltr_helper.rb 
  end
  
  def download_new_invoices
    require 'zip/zip'
    require 'zip/zipfilesystem'
    @company = @project.company
    invoices = IssuedInvoice.find_not_sent @project
    if invoices.size > 10
      flash[:error] = l(:too_much_invoices,:num=>invoices.size)
      redirect_to :action=>'index', :id=>@project
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
    redirect_to :action => 'index', :id => @project
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
      send_file "#{RAILS_ROOT}/public/plugin_assets/haltr/images/transparent.gif",
        :type => 'image/gif',
        :disposition => 'inline'
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

  private

  def find_hashid
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

  def create_pdf_file
    @is_pdf = true
    curr_lang = I18n.locale
    I18n.locale = @invoice.client.language rescue curr_lang
    pdf_file=Tempfile.new("invoice_#{@invoice.id}.pdf","tmp")
    xhtml_file=Tempfile.new("invoice_#{@invoice.id}.xhtml","tmp")
    xhtml_file.write(Iconv.conv('UTF-8//IGNORE', 'UTF-8', render_to_string(:action => "show", :layout => "invoice")))
    xhtml_file.close
    jarpath = "#{File.dirname(__FILE__)}/../../vendor/xhtmlrenderer"
    cmd="java -classpath #{jarpath}/core-renderer.jar:#{jarpath}/iText-2.0.8.jar:#{jarpath}/minium.jar org.xhtmlrenderer.simple.PDFRenderer #{xhtml_file.path} #{pdf_file.path}"
    logger.info "create_pdf_file command = #{cmd}"
    `#{cmd} 2>&1`
    I18n.locale = curr_lang
    $?.success? ? pdf_file : nil
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
    destination = './queued_file.data' if RAILS_ENV == "development"
    FileUtils.mv(invoice_file.path,destination)
    #TODO state restrictions
    @invoice.queue || @invoice.requeue
  end

  def render_clean_xml(options)
    xml = render_to_string(options)
    render :text => clean_xml(xml)
    response.content_type = 'application/xml'
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

end
