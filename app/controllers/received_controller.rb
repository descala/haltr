class ReceivedController < InvoicesController

  menu_item Haltr::MenuItem.new(:invoices,:received)

  skip_before_filter :check_for_company, :only=> [:index, :show]

  def show
    unless User.current.admin?
      @invoice.update_attribute(:has_been_read, true)
      if @invoice.created_from_invoice
        @invoice.created_from_invoice.read!
      end
    end
    super
  end

  def edit
    unless @invoice.invoice_format == 'pdf'
      flash[:error] = "Can't edit received invoices"
      redirect_to(:action=>'index',:project_id=>@project.id)
      return
    end
    super
  end

  def mark_accepted
    if params[:commit] == 'accept_with_mail'
      MailNotifier.delay.received_invoice_accepted(@invoice,params[:reason])
    end
    if @invoice.created_from_invoice
      Event.create(
        name: 'accept_notification',
        invoice_id: @invoice.created_from_invoice_id,
        user_id: User.current.id,
        notes: params[:reason]
      )
    end
    Event.create(:name=>'accept',:invoice=>@invoice,:user=>User.current, :notes => params[:reason])
    redirect_to :back
  rescue ActionController::RedirectBackError
    render :text => "OK"
  end

  def mark_refused
    if params[:commit] == 'refuse_with_mail'
      MailNotifier.delay.received_invoice_refused(@invoice,params[:reason])
    end
    if @invoice.created_from_invoice
      Event.create(
        name: 'refuse_notification',
        invoice_id: @invoice.created_from_invoice_id,
        user_id: User.current.id,
        notes: params[:reason]
      )
    end
    Event.create(:name=>'refuse',:invoice=>@invoice,:user=>User.current, :notes => params[:reason])
    redirect_to :back
  rescue ActionController::RedirectBackError
    render :text => "OK"
  end

  def bulk_mark_as
    all_changed = true
    if %w(accepted paid refused).include? params[:state]
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

  def validate
  end

  def bulk_validate
  end

  private

  def invoice_class
    ReceivedInvoice
  end

end
