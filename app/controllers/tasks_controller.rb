class TasksController < ApplicationController

  unloadable
  menu_item :haltr

  before_filter :find_project, :except => [:n19, :n19_done]
  before_filter :find_invoice, :only => [:n19, :n19_done]

  def index
    @num_new_invoices = @project.invoice_templates.collect {|i| i if i.date <= Date.parse((Time.now + 15.day).to_s) }.compact.size
    @num_not_sent = InvoiceDocument.find_not_sent(@project).size
    @charge_bank_on_due_date = InvoiceDocument.find_due_dates
  end

  def create_more
    @date = Time.now + 15.day
    templates = InvoiceTemplate.find :all, :conditions => ["date <= ?", @date]
    @invoices = []
    templates.each do |t|
      @invoices << t.next_invoice
    end
  end

  def automator
    @invoices = InvoiceDocument.find_not_sent(@project)
  end
  
  # generate spanish AEB Nº19
  def n19
    example_invoice = InvoiceDocument.find params[:id]
    @due_date = example_invoice.due_date
    @fecha_cargo = @due_date.to_formatted_s :ddmmyy
    @clients = Client.find :all, :conditions => ["bank_account != '' and project_id = ?",@project.id], :order => 'taxcode'
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
      render :layout => false
    else
      flash[:warning] = "No data for an Nº19"
      redirect_to :action => 'menu'
    end
  end
  
  def n19_done
    example_invoice = InvoiceDocument.find params[:id]
    invoices = InvoiceDocument.find :all, :conditions => ["due_date = ?",example_invoice.due_date]
    invoices.each do |invoice|
      invoice.status = Invoice::STATUS_CLOSED
      invoice.save
    end
    flash[:notice] = "Nº19 for due date #{example_invoice.due_date} maked as done"
    redirect_to :action => 'index', :id => @project
  end
  
  def report
    m = params[:id] || 3
    d = Date.today - m.to_i.months
    @date = Date.new(d.year,d.month,1)
    @invoices = InvoiceDocument.all(:conditions => ["date >= ?", @date], :order => :number)
    @total_amount = Money.new 0
    @total_tax = Money.new 0
    @invoices.each do |i|
      @total_amount +=  i.subtotal
      @total_tax    +=  i.tax
    end
  end
  
  private

  def find_project
    Project.send(:include, ProjectHaltrPatch) #TODO: perque nomes funciona el primer cop sense aixo?
    @project = Project.find(params[:id])
  end

  def find_invoice
    @invoice = InvoiceDocument.find params[:id]
    @project = @invoice.client.project
  end

end
