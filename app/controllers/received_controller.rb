class ReceivedController < InvoicesController

  menu_item Haltr::MenuItem.new(:invoices,:received)

  skip_before_action :check_for_company, :only=> [:index, :show]

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

  def parse_invoice_params
    parsed_params = super
    parsed_params['invoice_lines_attributes'].each do |i, invoice_line|
      invoice_line['taxes_attributes'] ||= {}

      iva = { name: 'IVA'  }
      iva['id'] = invoice_line.delete('tax_id')
      iva['percent'] = invoice_line.delete('tax_percent')
      iva['import'] = invoice_line.delete('tax_import')
      iva['category'] = invoice_line.delete('tax_category')
      iva.reject! {|k,v| v.blank? }
      iva['_destroy'] = 1 unless iva.keys.include?('percent') or iva.keys.include?('import')
      if iva.keys.size > 1
        invoice_line['taxes_attributes']['0'] = iva
      end

      irpf = { name: 'IRPF' }
      wh_percent = invoice_line.delete('tax_wh_percent')
      wh_import  = invoice_line.delete('tax_wh_import')
      wh_percent = "-#{wh_percent}" unless wh_percent.blank? or wh_percent =~ /-/
      wh_import  = "-#{wh_import}" unless wh_import.blank? or wh_import =~ /-/
      irpf['id'] = invoice_line.delete('tax_wh_id')
      irpf['percent'] = wh_percent
      irpf['import'] = wh_import
      irpf['category'] = invoice_line.delete('tax_wh_category')
      irpf.reject! {|k,v| v.blank? }
      irpf['_destroy'] = 1 unless irpf.keys.include?('percent') or irpf.keys.include?('import')
      if irpf.keys.size > 1
        invoice_line['taxes_attributes']['1'] = irpf
      end

    end
    parsed_params
  end

end
