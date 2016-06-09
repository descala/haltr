class ReceivedController < InvoicesController

  menu_item Haltr::MenuItem.new(:invoices,:received)

  skip_before_filter :check_for_company, :only=> [:index, :show]

  def show
    @invoice.update_attribute(:has_been_read, true)
    super
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
