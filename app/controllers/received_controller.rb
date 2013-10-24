class ReceivedController < InvoicesController

  menu_item Haltr::MenuItem.new(:invoices,:received)

  def index
    sort_init 'invoices.created_at', 'desc'
    sort_update %w(invoices.created_at state number date due_date clients.name import_in_cents)

    invoices = @project.invoices.scoped.where("type = ?","ReceivedInvoice")

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

  def show
    @invoice.update_attribute(:has_been_read, true)
    if @invoice.invoice_format == "pdf"
      render :template => 'received/show_pdf'
    else
      # TODO also show the database record version?
      if @invoice.fetch_from_backup
        doc  = Nokogiri::XML(@invoice.legal_invoice)
        xslt = Nokogiri::XSLT(render_to_string(:template=>'received/facturae32.xsl.erb',:layout=>false))
        @out  = xslt.transform(doc)
        render :template => 'received/show_with_xsl'
      else
        flash[:error] = l(:cant_connect_trace, "")
        render_404
      end
    end
  end

  def mark_accepted_with_mail
    MailNotifier.received_invoice_accepted(@invoice,params[:reason]).deliver
    mark_accepted
  end

  def mark_accepted
    Event.create(:name=>'accept',:invoice=>@invoice,:user=>User.current,:info=>params[:reason])
    redirect_to :back
  rescue ActionController::RedirectBackError
    render :text => "OK"
  end

  def mark_refused_with_mail
    MailNotifier.received_invoice_refused(@invoice,params[:reason]).deliver
    mark_refused
  end

  def mark_refused
    Event.create(:name=>'refuse',:invoice=>@invoice,:user=>User.current,:info=>params[:reason])
    redirect_to :back
  rescue ActionController::RedirectBackError
    render :text => "OK"
  end

  private

  def invoice_class
    ReceivedInvoice
  end

end
