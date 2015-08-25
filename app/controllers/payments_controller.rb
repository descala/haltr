class PaymentsController < ApplicationController

  unloadable
  menu_item Haltr::MenuItem.new(:payments,:payments_level2)
  menu_item Haltr::MenuItem.new(:payments,:payment_initiation), :only=> [:payment_initiation,:payment_done,:n19,:sepa,:invoices]
  menu_item Haltr::MenuItem.new(:payments,:import_aeb43),       :only=> [:import_aeb43_index,:import_aeb43]
  layout 'haltr'
  helper :haltr
  helper :sort

  include SortHelper

  before_filter :find_project_by_project_id, :except => [:destroy,:edit,:update]
  before_filter :find_payment,               :only   => [:destroy,:edit,:update]
  before_filter :authorize

  include CompanyFilter
  before_filter :check_for_company

  def index
    sort_init 'payments.date', 'desc'
    sort_update %w(payments.date amount_in_cents invoices.number)

    payments = @project.payments.includes('invoice')

    if params[:name].present?
      name = "%#{params[:name].strip.downcase}%"
      fields = %w(payments.payment_method reference
      DATE_FORMAT(payments.date,'%d-%m-%Y') invoices.number amount_in_cents)
      conditions = fields.collect {|f| "LOWER(#{f}) LIKE ?" }.join(' OR ')
      payments = payments.scoped conditions: [conditions, *fields.collect {name}]
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
          if @invoice.is_a? ReceivedInvoice
            MailNotifier.delay.received_invoice_paid(@payment.invoice,params[:reason])
          else
            MailNotifier.delay.issued_invoice_paid(@payment.invoice,params[:reason])
          end
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

  def payment_initiation
    @invoices_to_pay_by_bank_info = {}
    @project.company.bank_infos.each do |bi|
      @invoices_to_pay_by_bank_info[bi] = {}
      bi.invoices.find(:all,
        :conditions => ["state IN ('sent','registered') AND payment_method = ?", Invoice::PAYMENT_DEBIT],
      ).group_by(&:due_date).each do |due_date, invoices|
        @invoices_to_pay_by_bank_info[bi][due_date] = {}
        invoices.each do |invoice|
          unless invoice.client.bank_account.blank? and invoice.client.iban.blank?
            @invoices_to_pay_by_bank_info[bi][due_date]["n19"] ||= []
            @invoices_to_pay_by_bank_info[bi][due_date]["sepa_#{invoice.client.sepa_type}"] ||= []
            @invoices_to_pay_by_bank_info[bi][due_date]["n19"] << invoice
            @invoices_to_pay_by_bank_info[bi][due_date]["sepa_#{invoice.client.sepa_type}"] << invoice
          end
        end
        if @invoices_to_pay_by_bank_info[bi][due_date].blank?
          @invoices_to_pay_by_bank_info[bi].delete(due_date)
        end
      end
      if @invoices_to_pay_by_bank_info[bi].blank?
        @invoices_to_pay_by_bank_info.delete(bi)
      end
    end
  end

  # generate spanish AEB Nº19
  def n19
    @due_date         = Date.parse(params[:due_date])
    @fecha_cargo      = @due_date.to_formatted_s(:ddmmyy)
    @fecha_confeccion = Date.today.to_formatted_s(:ddmmyy)
    @bank_info        = BankInfo.find params[:bank_info]
    if @bank_info.bank_account.blank? and @bank_info.iban.blank?
      flash[:error] = l(:n19_requires_bank_account)
      redirect_to project_my_company_path(@project)
      return
    end
    @clients          = @bank_info.invoices.find(params[:invoices]).group_by(&:client)
    @total            = Money.new 0, Money::Currency.new(Setting.plugin_haltr['default_currency'])
    @clients.values.flatten.each do |invoice|
      @total += invoice.total
    end

    I18n.locale = :es
    output = render_to_string :layout => false
    send_data output, :filename => filename_for_content_disposition("n19-#{@fecha_cargo[4..5]}-#{@fecha_cargo[2..3]}-#{@fecha_cargo[0..1]}.txt"), :type => 'text/plain'
  end

  def sepa
    require "sepa_king"
    due_date = params[:due_date]
    bank_info = BankInfo.find params[:bank_info]
    render_404 && return if bank_info.blank?
    clients_all = Client.find(:all,
                          :conditions => ["iban != '' and project_id = ?", @project.id],
                          :order => 'taxcode')
    clients = clients_all.reject do |client|
      client.sepa_type != params[:sepa_type] || client.bank_invoices_total(due_date, bank_info.id).zero?
    end

    # Always use COR1
    if params[:sepa_type] == 'CORE'
      local_instrument = 'COR1'
    else
      local_instrument = 'B2B'
    end

    begin
      sdd = SEPA::DirectDebit.new(
        name:                @project.company.name,
        iban:                bank_info.iban,
        bic:                 bank_info.bic.blank? ? nil : bank_info.bic,
        creditor_identifier: @project.company.sepa_creditor_identifier,
      )

      sdd.message_identification="#{Setting['host_name']}/#{Time.now.to_i}"

      clients.each do |client|
        money = client.bank_invoices_total(due_date, bank_info.id)
        invoice_numbers =  client.bank_invoices(due_date, bank_info.id).collect do |i|
          i.number
        end.join(' ')
        sdd.add_transaction(
          name:                      client.name[0..69],
          iban:                      client.iban,
          bic:                       client.bic.blank? ? nil : client.bic,
          amount:                    money.dollars,
          mandate_id:                client.taxcode,
          mandate_date_of_signature: Date.new(2009,10,31),
          local_instrument:          local_instrument,
          sequence_type:             'RCUR',
          reference:                 "#{invoice_numbers}",
          remittance_information:    "#{l(:label_invoice)} #{invoice_numbers}",
          requested_date:            due_date.to_date,
        )
      end

      if clients.any?
        file_date = due_date.to_date.to_formatted_s(:number)
        send_data sdd.to_xml(SEPA::PAIN_008_001_02), :filename => filename_for_content_disposition("sepa-#{@project.identifier}-#{file_date}.xml"), :type => 'text/xml'
      else
        flash[:warning] = l(:notice_empty_sepa)
        redirect_to :action => 'payment_initiation', :project_id => @project
      end
    rescue ArgumentError, RuntimeError => e
      flash[:warning] = e.to_s
      redirect_to :action => 'payment_initiation', :project_id => @project
    end
  end
  
  def payment_done
    if params[:payment_type] == "sepa" and !User.current.allowed_to?(:use_sepa,@project)
      render_403
      return
    end
    bank_info = @project.company.bank_infos.find params[:bank_info]
    invoices  = bank_info.invoices.find(params[:invoices])
    invoices.each do |invoice|
      Payment.new_to_close(invoice).save
      invoice.close
    end
    flash[:notice] = l(:notice_payment_done, :payment_type => params[:payment_type], :value => params[:due_date])
    redirect_to :action => 'payment_initiation', :project_id => @project
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

  def invoices
    @invoices = @project.issued_invoices.find(params[:invoices])
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
