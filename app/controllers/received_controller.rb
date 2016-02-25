class ReceivedController < InvoicesController

  menu_item Haltr::MenuItem.new(:invoices,:received)

  def index
    sort_init 'invoices.created_at', 'desc'
    sort_update %w(invoices.created_at state number date due_date clients.name import_in_cents)

    invoices = @project.invoices.includes(:client).scoped.where("type = ?","ReceivedInvoice")

    # additional invoice filters
    if Redmine::Hook.call_hook(:additional_invoice_filters,:project=>@project,:invoices=>invoices).any?
      invoices = Redmine::Hook.call_hook(:additional_invoice_filters,:project=>@project,:invoices=>invoices)[0]
    end

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
      invoices = invoices.where("number like ?","%#{params[:number]}%")
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
    @invoice_pages = Paginator.new self, @invoice_count,
		per_page_option,
		params['page']
    @offset ||= @invoice_pages.current.offset
    @invoices =  invoices.find :all,
       :order => sort_clause,
       :include => [:client],
       :limit  =>  @limit,
       :offset =>  @offset

    @unread = invoices.where("type = ? AND has_been_read = ?", 'ReceivedInvoice', false).count
  end

  def show
    @invoice.update_attribute(:has_been_read, true)
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

  def mark_accepted_with_mail
    MailNotifier.delay.received_invoice_accepted(@invoice,params[:reason])
    mark_accepted
  end

  def mark_accepted
    Event.create(:name=>'accept',:invoice=>@invoice,:user=>User.current)
    redirect_to :back
  rescue ActionController::RedirectBackError
    render :text => "OK"
  end

  def mark_refused_with_mail
    MailNotifier.delay.received_invoice_refused(@invoice,params[:reason])
    mark_refused
  end

  def mark_refused
    Event.create(:name=>'refuse',:invoice=>@invoice,:user=>User.current)
    redirect_to :back
  rescue ActionController::RedirectBackError
    render :text => "OK"
  end

  def bulk_download
    require 'zip/zip'
    require 'zip/zipfilesystem'
    # just a safe big limit
    if @invoices.size > 100
      flash[:error] = l(:too_much_invoices,:num=>@invoices.size)
      redirect_to :action=>'index', :project_id=>@project
      return
    end
    zipped = []
    zip_file = Tempfile.new ["#{@project.identifier}_invoices", ".zip"], 'tmp'
    logger.info "Creating zip file '#{zip_file.path}' for invoice ids #{@invoices.collect{|i|i.id}.join(',')}."
    Zip::OutputStream.open(zip_file.path) do |zos|
      @invoices.each do |invoice|
        filename = invoice.file_name || 'invoice'
        file = Tempfile.new(filename)
        file.binmode
        file.write invoice.original
        logger.info "Created #{file.path}"
        file.close
        i=2
        while zipped.include?(filename)
          extension = File.extname(filename)
          base      = filename.gsub(/#{extension}$/,'')
          filename  = "#{base}_#{i}#{extension}"
          i += 1
        end
        zipped << filename
        zos.put_next_entry(filename)
        zos << IO.binread(file.path)
        logger.info "Added #{filename} from #{file.path}"
      end
    end
    zip_file.close
    send_file zip_file.path, :type => "application/zip", :filename => "#{@project.identifier}-invoices.zip"
  rescue LoadError
    flash[:error] = l(:zip_gem_required)
    redirect_to :action => 'index', :project_id => @project
  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH => e
    flash[:warning]=l(:cant_connect_trace, e.message)
    redirect_to :action => 'show', :id => @invoice
  end

  def bulk_mark_as
    all_changed = true
    @invoices.each do |i|
      next if i.state == params[:state]
      case params[:state]
      when "accepted"
        all_changed &&= (i.accept || i.unpaid)
      when "paid"
        all_changed &&= i.paid
      when "refused"
        all_changed &&= i.refuse
      else
        flash[:error] = "unknown state #{params[:state]}"
      end
    end
    flash[:warn] = l(:some_states_not_changed) unless all_changed
    redirect_back_or_default(:action=>'index',:project_id=>@project.id)
  end

  def validate
  end

  def bulk_validate
  end

  private

  def invoice_class
    ReceivedInvoice
  end

end
