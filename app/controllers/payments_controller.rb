class PaymentsController < ApplicationController

  unloadable
  menu_item Haltr::MenuItem.new(:payments,:payments_level2)
  menu_item Haltr::MenuItem.new(:payments,:charge_n19), :only=> [:n19_index,:n19,:n19_done]
  menu_item Haltr::MenuItem.new(:payments,:charge_sepa), :only=> [:sepa_index, :sepa]
  menu_item Haltr::MenuItem.new(:payments,:import_aeb43), :only=> [:import_aeb43_index,:import_aeb43]
  layout 'haltr'
  helper :haltr
  helper :sort

  include SortHelper

  before_filter :find_project_by_project_id, :only => [:index,:new,:create,:n19_index,:import_aeb43_index,:import_aeb43,:sepa_index]
  before_filter :find_payment, :only => [:destroy,:edit,:update]
  before_filter :find_invoice, :only => [:n19, :n19_done, :sepa]
  before_filter :authorize

  include CompanyFilter
  before_filter :check_for_company

  def index
    sort_init 'payments.date', 'desc'
    sort_update %w(payments.date amount_in_cents invoices.number)

    payments = @project.payments.scoped

    unless params[:name].blank?
      name = "%#{params[:name].strip.downcase}%"
      payments = payments.scoped :conditions => ["LOWER(payments.payment_method) LIKE ? OR LOWER(reference) LIKE ?", name, name]
    end

    @payment_count = payments.count
    @payment_pages = Paginator.new self, @payment_count,
		per_page_option,
		params['page']
    @payments = payments.find :all, :order => sort_clause,
       :include => :invoice,
       :limit  => @payment_pages.items_per_page,
       :offset => @payment_pages.current.offset
  end


  def new
    @payment_type = params[:payment_type]
    if params[:invoice_id]
      @invoice = Invoice.find params[:invoice_id]
      @payment = Payment.new(:invoice_id => @invoice.id, :amount => @invoice.unpaid_amount)
    else
      @payment = Payment.new
    end
  end

  def edit
  end

  def create
    @payment = Payment.new(params[:payment].merge({:project=>@project}))
    @invoice = @payment.invoice
    @reason = params[:reason]
    if @payment.save
      flash[:notice] = l(:notice_successful_create)
      if @payment.invoice
        if params[:save_and_mail]
          MailNotifier.invoice_paid(@payment.invoice,params[:reason]).deliver
        end
        if @payment.invoice.is_paid?
          # paid state change automatically creates an Event,
          # delete it and create new one with email info (params[:reason])
          @payment.invoice.events.last.destroy rescue nil
          Event.create(:name=>'paid',:invoice=>@payment.invoice,:user=>User.current,:info=>params[:reason])
        end
      end
      redirect_to project_payments_path(@project)
    else
      render :action => "new"
    end
  end

  def update
    if @payment.update_attributes(params[:payment])
      flash[:notice] = l(:notice_successful_update)
      redirect_to project_payments_path(@project)
    else
      render :action => "edit"
    end
  end

  def destroy
    @payment.destroy
    redirect_to project_payments_path(@project)
  end

  def n19_index
    @charge_bank_on_due_date = IssuedInvoice.find(:all, :conditions => ["state = 'sent' AND clients.bank_account != '' AND invoices.payment_method=? AND clients.project_id=?",Invoice::PAYMENT_DEBIT,@project.id], :include => :client).reject {|i|
      !i.bank_info or i.bank_info.bank_account.blank?
    }.group_by(&:bank_info)
  end

  # generate spanish AEB Nº19
  def n19
    @due_date = @invoice.due_date
    @fecha_cargo = @due_date.to_formatted_s :ddmmyy
    @bank_account = @invoice.bank_info.bank_account
    render_404 && return if @bank_account.blank?
    @clients = Client.find :all, :conditions => ["bank_account != '' and project_id = ?", @project.id], :order => 'taxcode'
    @fecha_confeccion = Date.today.to_formatted_s :ddmmyy
    @total = Money.new 0, Money::Currency.new(Setting.plugin_haltr['default_currency'])
    @clients.each do |client|
      money = client.bank_invoices_total(@due_date)
      @clients = @clients - [client] if money.zero?
      @total += money
    end

    if @clients.size > 0
      I18n.locale = :es
      output = render_to_string :layout => false
      send_data output, :filename => filename_for_content_disposition("n19-#{@fecha_cargo[4..5]}-#{@fecha_cargo[2..3]}-#{@fecha_cargo[0..1]}.txt"), :type => 'text/plain'
    else
      flash[:warning] = l(:notice_empty_n19)
      redirect_to :action => 'n19_index', :project_id => @project
    end
  end
  
  def n19_done
    invoices = IssuedInvoice.find :all, :include => [:client], :conditions => ["clients.project_id = ? and due_date = ? and invoices.payment_method = #{Invoice::PAYMENT_DEBIT}", @project.id, @invoice.due_date]
    invoices.each do |invoice|
      Payment.new_to_close(invoice).save
      invoice.close
    end
    flash[:notice] = l(:notice_n19_done, @invoice.due_date.to_s)
    redirect_to :action => 'n19_index', :project_id => @project
  end
 
  def import_aeb43_index
  end

  def import_aeb43
    file = params[:file]
    if file && file.size > 0
      importer = Import::Aeb43.new file.path
      @errors = []
      @moviments = importer.moviments
      @moviments.each do |m|
        if m.positiu
          begin
          p =Payment.new :date => m.date_o, :amount => m.amount, :payment_method => "Account #{m.account}", :reference => "#{m.ref1} #{m.ref2} #{m.txt1} #{m.txt2}".strip, :project => @project
          p.save!
          rescue ActiveRecord::RecordInvalid
            @errors << p
          end
        end
      end
    else
      flash[:warning] = l(:notice_uploaded_uploaded_file_not_found)
      redirect_to :action => 'import_aeb43_index', :project_id => @project
    end
  end

  def sepa_index
    @charge_bank_on_due_date = IssuedInvoice.find(:all, :conditions => ["state = 'sent' AND clients.bank_account != '' AND invoices.payment_method=? AND clients.project_id=?",Invoice::PAYMENT_DEBIT,@project.id], :include => :client).reject {|i|
      !i.bank_info or i.bank_info.iban.blank?
    }.group_by(&:bank_info)
  end

  def sepa
    @due_date = @invoice.due_date
    @fecha_cargo = @due_date.to_formatted_s :ddmmyy
    @bank_account = @invoice.bank_info.bank_account
    render_404 && return if @bank_account.blank?
    @clients = Client.find :all, :conditions => ["bank_account != '' and project_id = ?", @project.id], :order => 'taxcode'
    @fecha_confeccion = Date.today.to_formatted_s :ddmmyy
    @total = Money.new 0, Money::Currency.new(Setting.plugin_haltr['default_currency'])
    @clients.each do |client|
      money = client.bank_invoices_total(@due_date)
      @clients = @clients - [client] if money.zero?
      @total += money
    end

    if @clients.size > 0
      I18n.locale = :es
      output = render_to_string :layout => false
      send_data output, :filename => filename_for_content_disposition("n19-#{@fecha_cargo[4..5]}-#{@fecha_cargo[2..3]}-#{@fecha_cargo[0..1]}.txt"), :type => 'text/plain'
    else
      flash[:warning] = l(:notice_empty_n19)
      redirect_to :action => 'n19_index', :project_id => @project
    end
  end

  private

  def find_payment
    @payment = Payment.find(params[:id])
    @project = @payment.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_invoice
    @invoice = IssuedInvoice.find params[:id]
    @project = @invoice.project
  end


end
