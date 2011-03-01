class TasksController < ApplicationController

  unloadable
  menu_item :haltr_invoices
  menu_item :haltr_payments, :only => [:index,:n19,:n19_done,:import_aeb43]
  helper :haltr
  layout 'haltr'
  helper :invoices

  before_filter :find_project, :except => [:n19, :n19_done]
  before_filter :find_invoice, :only => [:n19, :n19_done]
  before_filter :authorize

  include CompanyFilter
  before_filter :check_for_company

  def index
    @charge_bank_on_due_date = IssuedInvoice.find_due_dates(@project)
  end

  def create_more
    @date = Time.now + 15.day
    templates = InvoiceTemplate.find :all, :include => [:client], :conditions => ["clients.project_id = ? and date <= ?", @project.id, @date]
    @invoices = []
    templates.each do |t|
      i = t.next_invoice
      if i.valid?
        @invoices << i
      else
        flash.now[:warning] = l(:warning_can_not_generate_invoice,t.to_s)
        flash.now[:error] = i.errors.full_messages.join ", "
      end
    end
  end

  def automator
    @invoices = IssuedInvoice.find_not_sent(@project)
  end
  
  # generate spanish AEB Nº19
  def n19
    @due_date = @invoice.due_date
    @fecha_cargo = @due_date.to_formatted_s :ddmmyy
    @clients = Client.find :all, :conditions => ["bank_account != '' and project_id = ?", @project.id], :order => 'taxcode'
    @fecha_confeccion = Date.today.to_formatted_s :ddmmyy
    @total = Money.new 0
    @clients.each do |client|
      money = client.bank_invoices_total(@due_date)
      @clients = @clients - [client] if money.zero?
      @total += money
    end

    if @clients.size > 0
      response.headers['Content-type'] = "text; charset=utf-8"
      response.headers['Content-disposition'] = "attachment; filename=n19-#{@fecha_cargo[4..5]}-#{@fecha_cargo[2..3]}-#{@fecha_cargo[0..1]}.txt"
      I18n.locale = :es
      render :layout => false
    else
      flash[:warning] = l(:notice_empty_n19)
      redirect_to :action => 'menu', :id => @project
    end
  end
  
  def n19_done
    invoices = IssuedInvoice.find :all, :include => [:client], :conditions => ["clients.project_id = ? and due_date = ?", @project.id, @invoice.due_date]
    invoices.each do |invoice|
      Payment.new_to_close(invoice).save
      invoice.close
    end
    flash[:notice] = l(:notice_n19_done, @invoice.due_date.to_s)
    redirect_to :action => 'index', :id => @project
  end
  
  def report
    m = params[:months_ago] || 3
    d = Date.today - m.to_i.months
    @date = Date.new(d.year,d.month,1)
    @invoices = IssuedInvoice.all(:include => [:client], :conditions => ["clients.project_id = ? and date >= ?", @project.id, @date], :order => :number)
    @total_amount = Money.new 0
    @total_tax = Money.new 0
    @invoices.each do |i|
      @total_amount +=  i.subtotal
      @total_tax    +=  i.tax
    end
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
          rescue ActiveRecord::RecordInvalid => e
            @errors << p
          end
        end
      end
    else
      flash[:warning] = l(:notice_uploaded_uploaded_file_not_found)
      redirect_to :action => 'index', :id => @project
    end
  end


  private

  def find_invoice
    @invoice = IssuedInvoice.find params[:id]
    @project = @invoice.project
  end

end
