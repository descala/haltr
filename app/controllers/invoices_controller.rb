class InvoicesController < ApplicationController

  menu_item Haltr::MenuItem.new(:invoices,:invoices_level2)
  menu_item Haltr::MenuItem.new(:invoices,:reports), :only => [:reports, :report_channel_state, :report_invoice_list, :report_received_table]
  helper :haltr
  helper :context_menus
  layout 'haltr'

  helper :sort
  include SortHelper
  helper :attachments
  include AttachmentsHelper

  PUBLIC_METHODS = [:by_taxcode_and_num,:view,:mail,:logo,:haltr_sign]

  before_filter :find_project_by_project_id, :only => [:index,:new,:create,:send_new_invoices,:download_new_invoices,:update_payment_stuff,:new_invoices_from_template,:reports,:report_channel_state,:report_invoice_list,:report_received_table,:create_invoices,:update_taxes,:upload,:import,:import_facturae]
  before_filter :find_invoice, :only => [:edit,:update,:mark_accepted_with_mail,:mark_accepted,:mark_refused_with_mail,:mark_refused,:duplicate_invoice,:base64doc,:show,:send_invoice,:amend_for_invoice,:original,:validate, :mark_as_accepted, :mark_as, :add_comment]
  before_filter :find_invoices, :only => [:context_menu,:bulk_download,:bulk_mark_as,:bulk_send,:destroy,:bulk_validate]
  before_filter :find_payment, :only => [:destroy_payment]
  before_filter :find_hashid, :only => [:view]
  before_filter :find_attachment, :only => [:logo]
  before_filter :find_invoice_by_number, only: [:number_to_id]
  before_filter :authorize, :except => PUBLIC_METHODS
  skip_before_filter :check_if_login_required, :only => PUBLIC_METHODS
  # on development skip auth so we can use curl to debug
  if Rails.env.development? or Rails.env.test?
    skip_before_filter :check_if_login_required, :only => [:by_taxcode_and_num,:view,:mail,:show,:original]
    skip_before_filter :authorize, :only => [:show,:original]
  else
    before_filter :check_remote_ip, :only => [:by_taxcode_and_num,:mail]
  end
  before_filter :redirect_to_correct_controller, :only => [:show]

  include CompanyFilter
  before_filter :check_for_company, :except => PUBLIC_METHODS

  skip_before_filter :verify_authenticity_token, :only => [:base64doc]
  accept_api_auth :import, :import_facturae, :number_to_id, :update, :show, :index, :destroy, :create, :send_invoice

  def index
    sort_init 'invoices.created_at', 'desc'
    sort_update %w(invoices.created_at state number date due_date clients.name import_in_cents)

    if self.class == ReceivedController
      invoices = @project.received_invoices
    else
      invoices = @project.issued_invoices
    end

    # additional invoice filters
    if Redmine::Hook.call_hook(:additional_invoice_filters,:project=>@project,:invoices=>invoices).any?
      invoices = Redmine::Hook.call_hook(:additional_invoice_filters,:project=>@project,:invoices=>invoices)[0]
    end

    if params[:invoices]
      invoices = invoices.where(["invoices.id in (?)",params[:invoices]])
    end

    unless params["state_all"] == "1"
      statelist=[]
      %w(new sending sent read error cancelled closed discarded registered refused accepted allegedly_paid accounted).each do |state|
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
      invoices = invoices.where("invoices.client_id = ?", params[:client_id])
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
      invoices = invoices.includes(:client).references(:client).where("clients.taxcode like ?","%#{params[:taxcode]}%")
    end
    unless params[:name].blank?
      invoices = invoices.includes(:client).references(:client).includes(:client_office).references(:client_office).where("clients.name like ? or client_offices.name like ?","%#{params[:name]}%","%#{params[:name]}%")
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

    # client invoice_format filter
    unless params[:invoice_format].blank?
      invoices = invoices.includes(:client).references(:client).where("clients.invoice_format = ?", params[:invoice_format])
    end

    # filter by text
    unless params[:has_text].blank?
      invoices = invoices.includes(:invoice_lines).references(:invoice_lines).where("invoices.extra_info like ? or invoice_lines.description like ? or invoice_lines.notes like ?", "%#{params[:has_text]}%", "%#{params[:has_text]}%", "%#{params[:has_text]}%")
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
    @invoice_pages = Paginator.new @invoice_count, @limit, params['page']
    @offset ||= @invoice_pages.offset
    @invoices = invoices.order(sort_clause).limit(@limit).offset(@offset).includes(:client).to_a

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
    @invoice = invoice_class.new(:client=>@client,:project=>@project,:date=>Date.today,:number=>IssuedInvoice.next_number(@project))
    @invoice.currency = @client.currency if @client
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
    if @invoice.partially_amended_id
      @to_amend = Invoice.find @invoice.partially_amended_id rescue nil
      @amend_type = 'partial'
    else
      @to_amend = Invoice.find_by_amend_id @invoice.id
      @amend_type = 'total'
    end
  end

  def create
    # mark as "_destroy" all taxes with an empty tax code
    # and copy global "exempt comment" to all exempt taxes
    parsed_params = parse_invoice_params

    # accept client as a Hash with its data
    client_hash = parsed_params.delete(:client)

    # accept bank_account, for client or company
    bank_account = parsed_params.delete(:bank_account)
    iban         = parsed_params.delete(:iban)

    # accept dir3 info
    unless parsed_params[:oficina_comptable].is_a? String
      oficina_comptable = parsed_params.delete(:oficina_comptable)
      if oficina_comptable
        parsed_params[:oficina_comptable] = oficina_comptable[:code]
        if client_hash
          Dir3Entity.new_from_hash(oficina_comptable, client_hash[:taxcode], '01')
        else
          Dir3Entity.new_from_hash(oficina_comptable)
        end
      end
    end
    unless parsed_params[:organ_gestor].is_a? String
      organ_gestor = parsed_params.delete(:organ_gestor)
      if organ_gestor
        parsed_params[:organ_gestor] = organ_gestor[:code]
        if client_hash
          Dir3Entity.new_from_hash(organ_gestor, client_hash[:taxcode], '02')
        else
          Dir3Entity.new_from_hash(organ_gestor)
        end
      end
    end
    unless parsed_params[:unitat_tramitadora].is_a? String
      unitat_tramitadora = parsed_params.delete(:unitat_tramitadora)
      if unitat_tramitadora
        parsed_params[:unitat_tramitadora] = unitat_tramitadora[:code]
        if client_hash
          Dir3Entity.new_from_hash(unitat_tramitadora, client_hash[:taxcode], '03')
        else
          Dir3Entity.new_from_hash(unitat_tramitadora)
        end
      end
    end
    unless parsed_params[:organ_proponent].is_a? String
      organ_proponent = parsed_params.delete(:organ_proponent)
      if organ_proponent
        parsed_params[:organ_proponent] = organ_proponent[:code]
        if client_hash
          Dir3Entity.new_from_hash(organ_proponent, client_hash[:taxcode], '03')
        else
          Dir3Entity.new_from_hash(organ_proponent)
        end
      end
    end

    @invoice = invoice_class.new(parsed_params)
    @invoice.project ||= @project

    if @invoice.fa_country.to_s.size == 3
      @invoice.fa_country = SunDawg::CountryIsoTranslater.translate_standard(
        @invoice.fa_country, "alpha3", "alpha2"
      ).downcase rescue @invoice.fa_country
    end

    if client_hash
      client_hash[:project] = @invoice.project
      @invoice.client, @invoice.client_office = Haltr::Utils.client_from_hash(client_hash)
    end

    if bank_account || iban
      begin
        @invoice.set_bank_info(bank_account, iban, nil)
      rescue
        @invoice.errors.add(:base, $!.message)
        respond_to do |format|
          format.html { render :action => 'new' }
          format.api { render_validation_errors(@invoice) }
        end
        return
      end
    end

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

    @invoice.client_office = nil unless @client and @client.client_offices.any? {|office| office.id == @invoice.client_office_id }
    @invoice.company_office = nil unless @project.company.company_offices.any? {|office| office.id == @invoice.company_office_id }

    if params[:to_amend] and params[:amend_type]
      @to_amend = @project.invoices.find params[:to_amend]
      @amend_type = params[:amend_type]
      case params[:amend_type]
      when 'total'
        @to_amend.amend = @invoice
        @invoice.amend_reason = '16'
      when 'partial'
        @invoice.partially_amended_id = @to_amend.id
      else
        raise "unknown amend type: #{params[:amend_type]}"
      end
      @invoice.amended_number = @to_amend.number
    end

    if Redmine::Hook.call_hook(:invoice_before_create,:project=>@project,:invoice=>@invoice,:params=>params).any?
      @invoice = Redmine::Hook.call_hook(:invoice_before_create,:project=>@project,:invoice=>@invoice,:params=>params)[0]
    end

    # prevent duplicate invoices #5433 #5891
    validate = params[:validate] != 'false'
    if !validate and !@invoice.valid? and @invoice.errors.has_key?(:number)
      validate = true
    end
    if @invoice.save(validate: validate)
      if @to_amend and params[:amend_type] == 'total'
        @to_amend.save(validate: false)
        @to_amend.amend_and_close!
      end
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
        format.api {
          if @invoice and ["true","1"].include?(params[:send_after_import])
            begin
              Haltr::Sender.send_invoice(@invoice, User.current)
              @invoice.queue!
            rescue
            end
          end
          render :action => 'show', :status => :created, :location => invoice_url(@invoice)
        }
      end
    else
      logger.info "Invoice errors #{@invoice.errors.full_messages}"
      # Add a client in order to render the form with the errors
      @client ||= Client.where("project_id = ?", @project).order('name').first
      @client ||= Client.new

      respond_to do |format|
        format.html { render :action => (@to_amend ? 'amend_for_invoice' : 'new') }
        format.api { render_validation_errors(@invoice) }
      end
    end
  end

  def update
    if @invoice.partially_amended_id
      @to_amend = Invoice.find @invoice.partially_amended_id rescue nil
      @amend_type = 'partial'
    else
      @to_amend = Invoice.find_by_amend_id @invoice.id
      @amend_type = 'total'
    end
    @invoice.save_attachments(params[:attachments] || (params[:invoice] && params[:invoice][:uploads]))

    #TODO: need to access invoice taxes before update_attributes, if not
    # updated taxes are not saved.
    # maybe related to https://rails.lighthouseapp.com/projects/8994/tickets/4642
    @invoice.invoice_lines.each {|l| l.taxes.each {|t| } }

    # mark as "_destroy" all taxes with an empty tax code
    # and copy global "exempt comment" to all exempt taxes
    parsed_params = parse_invoice_params

    if params[:invoice][:client_id]
      @invoice.client_office = nil unless Client.find(params[:invoice][:client_id]).client_offices.any? {|office| office.id == @invoice.client_office_id }
    end

    if @invoice.update_attributes(parsed_params)
      # mark invoice as new
      if %w(sent registered accepted allegedly_paid closed).include?(@invoice.state)
        @invoice.update_attribute(:state, 'new')
      end

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
        invoice.events.destroy_all
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
        if @invoice.queue!
          Haltr::Sender.send_invoice(@invoice, User.current, true, file)
          logger.info "Invoice #{@invoice.id} #{file.path} queued"
          render :text => "Document sent. document = #{file}"
        else
          logger.info "Invoice #{@invoice.id}: #{l(:state_not_allowed_for_sending, state: l("state_#{@invoice.state}"))}"
          render text: l(:state_not_allowed_for_sending, state: l("state_#{@invoice.state}"))
        end
      else
        render :text => "Missing document"
      end
    end
  end

  def show
    invoice_nokogiri = nil
    @invoice_pdf = nil
    unless %w(original sent db).include?(params[:view])
      if @invoice.original and @invoice.send_original?
        params[:view] = @company.invoice_viewer
      end
    end
    case params[:view]
    when 'original'
      if @invoice.invoice_format == 'pdf'
        flash.now[:error] = l(:pdf_shows_original) unless @invoice.send_original?
        @invoice_pdf = invoices_original_path(@invoice, format: 'pdf')
      else
        invoice_nokogiri = Nokogiri::XML(@invoice.original)
      end
    when 'sent'
      if @invoice.last_success_sending_event
        if @invoice.last_success_sending_event.content_type == 'application/pdf'
          attachment = @invoice.last_success_sending_event.attachments.first
          @invoice_pdf = download_named_attachment_path(attachment, attachment.filename)
        else
          invoice_nokogiri = Nokogiri::XML(@invoice.last_success_sending_event.attachment_content)
          begin
            if invoice_nokogiri.root.namespace.href =~ /StandardBusinessDocumentHeader/
              invoice_nokogiri = Haltr::Utils.extract_from_sbdh(invoice_nokogiri)
            end
          rescue
          end
          template = original_xsl_template(invoice_nokogiri)
        end
      else
      end
    when 'db'
      # continue
    end
    if invoice_nokogiri
      # show a xml with xslt
      begin
        if invoice_nokogiri.root.namespace.href =~ /StandardBusinessDocumentHeader/
          invoice_nokogiri = Haltr::Utils.extract_from_sbdh(invoice_nokogiri)
        end
      rescue
      end
      template = original_xsl_template(invoice_nokogiri)
      if template
        if params[:view] == 'original' and !@invoice.send_original?
          flash.now[:error] = l(:xslt_shows_original)
        end
        @invoice_root_namespace = Haltr::Utils.root_namespace(invoice_nokogiri) rescue nil
        xslt = render_to_string(:template=>template,:layout=>false)
        @invoice_xslt_html = Nokogiri::XSLT(xslt).transform(invoice_nokogiri)
      elsif @invoice.original
        flash[:error] = l(:xslt_not_available)
        unless @invoice.is_a?(ReceivedInvoice)
          redirect_to(action: 'show', id: @invoice)
        end
        return
      end
    end

    set_sent_and_closed
    @js = ExportChannels[@client.invoice_format]['javascript'] rescue nil
    @autocall = params[:autocall]
    @autocall_args = params[:autocall_args]
    @format = params["format"]
    respond_to do |format|
      format.html do
        render :template => 'invoices/show_with_xsl' if @invoice_xslt_html
      end
      format.api do
        # Force "json" if format is emtpy
        # Used in refresher.js to check invoice status
        params[:format] ||= 'json'
      end
      format.pdf do
        if @invoice.send_original? and @invoice.invoice_format == 'pdf'
          send_data @invoice.original,
            :type => 'application/pdf',
            :filename => @invoice.file_name,
            :disposition => 'attachment'
        else
          @is_pdf = true
          @debug = params[:debug]
          render :pdf => @invoice.pdf_name_without_extension,
            :disposition => params[:disposition] == 'inline' ? 'inline' : 'attachment',
            :layout => "invoice.html",
            # TODO
            # :template=> show_original ? "invoice/show_with_xsl" : "invoices/show_pdf",
            :template=> "invoices/show_pdf",
            :formats => :html,
            :show_as_html => params[:debug],
            :margin => {
              :top    => 20,
              :bottom => 20,
              :left   => 30,
              :right  => 20
            }
        end
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
        format.original {
          ct = ExportFormats[@invoice.invoice_format]["content-type"] rescue ""
          case ct
          when 'text-xml'
            render_xml @invoice.original
          when 'application-pdf'
            send_data @invoice.original,
              :type => 'application/pdf',
              :filename => @invoice.pdf_name,
              :disposition => 'attachment'
          else
            render text: "Unknown original format: #{@invoice.invoice_format}"
          end
        }
        format.edifact     { render text: Haltr::Edifact.generate(@invoice, false, true), content_type: 'text' }
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
        format.original {
          ct = ExportFormats[@invoice.invoice_format]["content-type"] rescue ""
          case ct
          when 'text-xml'
            render_xml @invoice.original
          when 'application-pdf'
            send_data @invoice.original,
              :type => 'application/pdf',
              :filename => @invoice.pdf_name,
              :disposition => 'attachment'
          else
            render text: "Unknown original format: #{@invoice.invoice_format}"
          end
        }
        format.edifact     { download_txt Haltr::Edifact.generate(@invoice, false, true) }
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

  def download_txt(txt)
    send_data txt,
      :type => 'text; charset=UTF-8;',
      :disposition => "attachment; filename=#{@invoice.pdf_name_without_extension}.txt"
  end

  def send_invoice
    unless @invoice.valid?
      raise @invoice.errors.full_messages.join(', ')
    end
    unless ExportChannels.can_send? @invoice.client.invoice_format
      raise "#{l(:export_channel)}: #{ExportChannels.l(@invoice.client.invoice_format)}"
    end
    if @invoice.queue!
      Haltr::Sender.send_invoice(@invoice, User.current)
      respond_to do |format|
        format.html do
          flash[:notice] = "#{l(:notice_invoice_sent)}"
        end
        format.api do
          render_api_ok
        end
      end
    else
      error = l(:state_not_allowed_for_sending, state: l("state_#{@invoice.state}"))
      respond_to do |format|
        format.html do
          flash[:error] = error
        end
        format.api do
          @error_messages = [error]
          render :template => 'common/error_messages.api', :status => :unprocessable_entity, :layout => nil
        end
      end
    end
  rescue Exception => e
    # e.backtrace does not fit in session leading to
    #   ActionController::Session::CookieStore::CookieOverflow
    msg = "#{l(:error_invoice_not_sent, :num=>@invoice.number)}: #{e.message}"
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
    # Get notifications of type NameError if ExceptionNotifier is installed
    if defined?(ExceptionNotifier) and e.is_a?(NameError)
      ExceptionNotifier.notify_exception(e)
    end
    #raise e if Rails.env == "development"
    respond_to do |format|
      format.html do
        flash[:error] = msg
      end
      format.api do
        @error_messages = [msg]
        render :template => 'common/error_messages.api', :status => :unprocessable_entity, :layout => nil
      end
    end
  ensure
    respond_to do |format|
      format.html do
        redirect_back_or_default(:action => 'show', :id => @invoice)
      end
      format.api do
      end
    end
  end

  def send_new_invoices
    @invoices = IssuedInvoice.find_can_be_sent(@project).order("number ASC")
    bulk_send
    render action: 'bulk_send'
  end

  def download_new_invoices
    require 'zip'
    @company = @project.company
    invoices = IssuedInvoice.find_not_sent(@project).order("number ASC")
    # just a safe big limit
    if invoices.size > 100
      flash[:error] = l(:too_much_invoices,:num=>invoices.size)
      redirect_to :action=>'index', :project_id=>@project
      return
    end
    zip_file = Tempfile.new "#{@project.identifier}_invoices.zip", 'tmp'
    logger.info "Creating zip file '#{zip_file.path}' for invoice ids #{invoices.collect{|i|i.id}.join(',')}."
    Zip::OutputStream.open(zip_file.path) do |zos|
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
      query = IssuedInvoice.where(number: params[:num], project_id: project)
      query = query.where(date: params[:date]) if params[:date]
      invoice = query.last if project
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
  # has a setting in haltr plugin conf to require clients to register
  def view
    @client_hashid = params[:client_hashid]
    if User.current.logged? and User.current.project and
        User.current.project != @invoice.project and
        (User.current.project.company.taxcode == @invoice.client.taxcode or
         User.current.project.company.taxcode.blank?)
      user_company = User.current.project.company
      unless user_company.company_providers.include?(@invoice.project.company)
        # add project to providers
        user_company.company_providers << @invoice.project.company
        # create received invoices
        @invoice.project.issued_invoices.select {|i| i.client == @invoice.client }.each do |issued|
          ReceivedInvoice.create_from_issued(issued, User.current.project)
        end
      end
      # redirect to received invoice
      received = User.current.project.received_invoices.find_by_number_and_series_code(
        @invoice.number, @invoice.series_code
      )
      if received
        redirect_to received_invoice_path(received)
      else
        #TODO: warn about invoice not found?
        redirect_to controller: 'received', action: 'index', project_id: User.current.project
      end
      return
    elsif !User.current.logged?
      if Setting['plugin_haltr']['view_invoice_requires_login']
        # ask user to login/register
        redirect_to signin_path(client_hashid: @client_hashid, invoice_id: @invoice.id)
        return
      end
    end

    @lsse = @invoice.last_success_sending_event
    if @lsse
      @invoice_url = client_event_attachment_path(@lsse, client_hashid: @invoice.client.hashid)
      if @lsse.content_type == 'application/xml'
        invoice_nokogiri = Nokogiri::XML(@lsse.attachment_content)
        template = original_xsl_template(invoice_nokogiri)
        if template
          @invoice_root_namespace = Haltr::Utils.root_namespace(invoice_nokogiri) rescue nil
          xslt = render_to_string(:template=>template,:layout=>false)
          begin
            if invoice_nokogiri.root.namespace.href =~ /StandardBusinessDocumentHeader/
              invoice_nokogiri = Haltr::Utils.extract_from_sbdh(invoice_nokogiri)
            end
            @invoice_xslt_html = Nokogiri::XSLT(xslt).transform(invoice_nokogiri)
          rescue
            flash[:warning]=$!.message
          end
        end
      end
    end

    @lines = @invoice.invoice_lines
    set_sent_and_closed
    @invoices_not_sent = []
    unless @invoice.has_been_read or User.current.projects.include?(@invoice.project) or User.current.admin?
      Event.create!(:name=>'read',:invoice=>@invoice,:user=>User.current)
      @invoice.update_attribute(:has_been_read,true)
      @invoice.read
    end
    render :layout=>"public"
  rescue ActionView::MissingTemplate
    nil
  rescue Exception => e
    flash[:error]=e.message
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

  def amend_for_invoice
    @to_amend = @invoice
    @amend_type = params[:amend_type]
    @invoice = IssuedInvoice.new(
      @to_amend.attributes.update(
        state: 'new',
        number: IssuedInvoice.next_number(@project)
      ),
      amend_reason: '16',
      amended_number: @to_amend.number
    )
    @to_amend.invoice_lines.each do |line|
      il = line.dup
      il.taxes = line.taxes.collect {|tax| tax.dup }
      @invoice.invoice_lines << il
    end
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
    @from     = params[:date_from]
    @to       = params[:date_to]
    @from = 3.months.ago if @from.blank?
    @to   = Date.today   if @to.blank?
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

  def report_received_table
    @from     = params[:date_from_received]
    @to       = params[:date_to_received]
    @from = 3.months.ago if @from.blank?
    @to   = Date.today   if @to.blank?
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
    invoices = @project.received_invoices.includes(:client).where(
      ["date >= ? and date <= ? and client_id is not null", @from, @to]
    ).order(:number)
    invoices = invoices.where("date >= ?", @from).where("date <= ?", @to)
    @months = invoices.to_a.group_by_month(&:date)
    @clients = invoices.to_a.group_by(&:client).sort
    @client_totals = {}
    @clients.each do |client, client_invoices|
      @client_totals[client] = client_invoices.sum(&:total)
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
    invoices = IssuedInvoice.where(["client_id=? AND id=?",@client.id,params[:invoice_id]]).all.to_a.delete_if { |i| !i.visible_by_client? }
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
    if @invoice.client_office
      # overwrite client attributes with its office
      ClientOffice::CLIENT_FIELDS.each do |f|
        @client[f] = @invoice.client_office.send(f)
      end
      # client copies linked profile before validation, so remove link
      # to prevent fields beign overwritten
      @client[:company_id] = nil
    end
    if @invoice.company_office
      # overwrite company attributes with its office
      CompanyOffice::COMPANY_FIELDS.each do |f|
        @company[f] = @invoice.company_office.send(f)
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_invoices
    @invoices = invoice_class.where(id: (params[:id] || params[:ids]))
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
      redirect_to(received_invoice_path(@invoice, format: params[:format])) && return
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
    unless ExportFormats.available.keys.include?(params[:in]) or params[:controller]=='received'
      flash[:error] = "unknown format #{params[:in]}"
      redirect_back_or_default(:action=>'index',:project_id=>@project.id)
      return
    end
    require 'zip'
    # just a safe big limit
    if @invoices.size > 100
      flash[:error] = l(:too_much_invoices,:num=>@invoices.size)
      redirect_to :action=>'index', :project_id=>@project
      return
    end
    zip_file = Tempfile.new ["#{@project.identifier}_invoices", ".zip"], 'tmp'
    logger.info "Creating zip file '#{zip_file.path}' for invoice ids #{@invoices.collect{|i|i.id}.join(',')}."
    Zip::OutputStream.open(zip_file.path) do |zos|
      @invoices.each do |invoice|
        @invoice = invoice
        @lines = @invoice.invoice_lines
        @client = @invoice.client
        if invoice.is_a? ReceivedInvoice
          filename = invoice.file_name || "invoice_#{invoice.id}.#{invoice.invoice_format}"
          zos.put_next_entry(filename)
          zos.print invoice.original
        else
          file_name = @invoice.pdf_name_without_extension
          file_name += (params[:in] == "pdf" ? ".pdf" : ".xml")
          zos.put_next_entry(file_name)
          if params[:in] == "pdf"
            zos.print Haltr::Pdf.generate(@invoice)
          else
            zos.print Haltr::Xml.generate(@invoice,params[:in])
          end
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
    states = @invoice.is_a?(ReceivedInvoice) ? %w(paid) :
      %w(new sent accepted registered refused closed)
    if states.include? params[:state]
      @invoice.send("mark_as_#{params[:state]}!")
      @invoice.update_attribute(:state, params[:state])
      Event.create(
        name: "done_mark_as_#{params[:state]}",
        invoice: @invoice,
        user: User.current
      )
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
        all_changed = i.send("mark_as_#{params[:state]}!") && all_changed
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
      if invoice.valid? and invoice.may_queue? and
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
        elsif !invoice.may_queue?
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

  # Used in API only - facturae in multipart POST 'file' field
  def import
    if request.post?
      file = params[:file]
      @invoice = nil
      unless params[:issued].nil?
        @issued = ( params[:issued] == 'true' )
      else
        @issued = nil
      end
      if file && file.size > 0
        md5 = `md5sum #{file.path} | cut -d" " -f1`.chomp
        user_or_company = User.current.admin? ? @project.company : User.current
        transport = params[:transport] || 'uploaded'
        @invoice = Invoice.create_from_xml(
          file, user_or_company, md5,transport,nil,
          @issued,
          params['keep_original'] != 'false',
          params['validate'] != 'false',
          params['override_original'],
          params['override_original_name']
        )
      end
      if @invoice and ["true","1"].include?(params[:send_after_import])
        begin
          Haltr::Sender.send_invoice(@invoice, User.current)
          @invoice.queue!
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
    else
      @issued = ( self.class != ReceivedController )
    end
  rescue
    respond_to do |format|
      format.html {
        raise $! unless $!.is_a?(StandardError)
        flash[:error] = $!.message
        redirect_to :action => 'import', :project_id => @project
      }
      format.api {
        @error_messages = [$!.message]
        render :template => 'common/error_messages.api', :status => :unprocessable_entity, :layout => nil
      }
    end
  end

  # Used in form POST - multiple file upload
  def upload
    if request.post?
      @invoice = nil
      unless params[:issued].nil?
        @issued = ( params[:issued] == 'true' )
      else
        @issued = nil
      end
      errors =  []
      transport = params[:transport] || 'uploaded'
      params[:attachments].each do |key, attachment_param|
        begin
          attachment = Attachment.find_by_token(attachment_param['token'])
          if attachment.content_type.blank?
            # http://stackoverflow.com/questions/51572
            attachment.content_type =
              IO.popen(["file", "--brief", "--mime-type", attachment.diskfile],
                       in: :close, err: :close) { |io| io.read.chomp }
          end
          case attachment.content_type
          when /xml/
            user_or_company = User.current.admin? ? @project.company : User.current
            @invoice = Invoice.create_from_xml(
              File.read(attachment.diskfile),
              user_or_company, attachment.digest, transport,nil,
              @issued,
              params['keep_original'] != 'false',
              params['validate'] != 'false',
              params['override_original'],
              params['override_original_name']
            )
            if @invoice and ["true","1"].include?(params[:send_after_import])
              begin
                Haltr::Sender.send_invoice(@invoice, User.current)
                @invoice.queue
              rescue
              end
            end
          when /pdf/
            @invoice = params[:issued] == '1' ? IssuedInvoice.new : ReceivedInvoice.new
            @invoice.project   = @project
            @invoice.state     = :processing_pdf
            @invoice.transport = transport
            @invoice.md5       = attachment.digest
            @invoice.original  = File.binread(attachment.diskfile)
            @invoice.invoice_format = 'pdf'
            @invoice.has_been_read = true
            @invoice.file_name = attachment.filename
            @invoice.save(validate: false)
            Event.create(:name=>'processing_pdf',:invoice=>@invoice)
            Haltr::SendPdfToWs.send(@invoice)
          else
            errors <<  "unknown file type: '#{attachment.content_type}' for #{attachment.filename}"
          end
        ensure
          # Attachments are only temporaly used to create Invoices
          attachment.destroy if attachment
        end
      end
      if errors.size > 0
        raise errors.join
      end
      respond_to do |format|
        format.html {
          if @invoice
            if params[:attachments].count > 1
              if self.class == ReceivedController
                redirect_to project_received_index_path
              else
                redirect_to project_invoices_path
              end
            else
              redirect_to invoice_path(@invoice)
            end
          else
            flash[:warning] = l(:notice_uploaded_file_not_found)
            redirect_to :action => 'upload', :project_id => @project
          end
        }
        format.api {
          render action: 'show', status: :created, location: invoice_path(@invoice)
        }
      end
    else
      @issued = ( self.class != ReceivedController )
    end
  rescue
    respond_to do |format|
      format.html {
        raise $! unless $!.is_a?(StandardError)
        flash[:error] = $!.message
        redirect_to :action => 'upload', :project_id => @project
      }
      format.api {
        @error_messages = [$!.message]
        render :template => 'common/error_messages.api', :status => :unprocessable_entity, :layout => nil
      }
    end
  end

  def original
    fn = nil
    if @invoice.is_a? ReceivedInvoice
      fn = @invoice.file_name
    end
    if @invoice.invoice_format == 'pdf'
      send_data @invoice.original,
        :type => 'application/pdf',
        :filename => fn || @invoice.pdf_name,
        :disposition => params[:disposition] == 'inline' ? 'inline' : 'attachment'
    else
      send_data @invoice.original,
        :type => 'text/xml; charset=UTF-8;',
        :disposition => "attachment; filename=#{fn || @invoice.xml_name}"
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
    @invoice = @project.invoices.find_last_by_number(params[:number])
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

  def original_xsl_template(doc)
    namespace = Haltr::Utils.root_namespace(doc) rescue nil
    case namespace
    when "http://www.facturae.es/Facturae/2014/v3.2.1/Facturae", "http://www.facturae.es/Facturae/2009/v3.2/Facturae"
      'invoices/facturae_xslt_viewer.xsl'
    when "urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"
      'invoices/TRDM-010a-Invoice-NO.xsl'
    else
      nil
    end
  end

  def parse_invoice_params
    parsed_params = params[:invoice] || {}
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
      # discounts percent and amount #5516
      discount = invoice_line.delete(:discount).to_s.gsub(/-/,'')
      discount_type = invoice_line.delete(:discount_type)
      if discount_type == '€'
        invoice_line[:discount_percent] = 0
        invoice_line[:discount_amount] = discount
      elsif discount_type == '%'
        invoice_line[:discount_percent] = discount
        invoice_line[:discount_amount] = 0
      end
    end
    # discounts percent and amount #5516
    discount = parsed_params.delete(:discount)
    discount_type = parsed_params.delete(:discount_type)
    if discount_type == '€'
      parsed_params[:discount_percent] = 0
      parsed_params[:discount_amount] = discount
    elsif discount_type == '%'
      parsed_params[:discount_percent] = discount
      parsed_params[:discount_amount] = 0
    end
    parsed_params
  end

  def set_sent_and_closed
    @invoices_not_sent = InvoiceDocument.where(["client_id = ? and state = 'new'",@client.id]).order("id desc").limit(10)
    @invoices_not_sent_count = InvoiceDocument.where(["client_id = ? and state = 'new'",@client.id]).order("id desc").count
    @invoices_sent = InvoiceDocument.where(["client_id = ? and state = 'sent'",@client.id]).order("id desc").limit(10)
    @invoices_sent_count = InvoiceDocument.where(["client_id = ? and state = 'sent'",@client.id]).order("id desc").count
    @invoices_closed = InvoiceDocument.where(["client_id = ? and state = 'closed'",@client.id]).order("id desc").limit(10)
    @invoices_closed_count = InvoiceDocument.where(["client_id = ? and state = 'closed'",@client.id]).order("id desc").count
  end

end
