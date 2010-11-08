class PaymentsController < ApplicationController

  unloadable
  menu_item :haltr

  helper :sort
  include SortHelper

  before_filter :find_project, :except => [:destroy,:edit,:update]
  before_filter :find_payment, :only   => [:destroy,:edit,:update]
  before_filter :authorize

  def index
    sort_init 'date', 'asc'
    sort_update %w(payments.date amount_in_cents invoices.number)

    c = ARCondition.new(["project_id = ?", @project])

    unless params[:name].blank?
      name = "%#{params[:name].strip.downcase}%"
      c << ["LOWER(method) LIKE ? OR LOWER(reference) LIKE ?", name, name]
    end

    @payment_count = Payment.count(:conditions => c.conditions, :include => :invoice)
    @payment_pages = Paginator.new self, @payment_count,
		per_page_option,
		params['page']
    @payments = Payment.find :all, :order => sort_clause,
       :conditions => c.conditions,
       :include => :invoice,
       :limit  => @payment_pages.items_per_page,
       :offset => @payment_pages.current.offset

    render :action => "index", :layout => false if request.xhr?

  end


  def new
    @payment = Payment.new
  end

  def edit
  end

  def create
    @payment = Payment.new(params[:payment].merge({:project=>@project}))
    if @payment.save
      flash[:notice] = 'Payment was successfully created.'
      redirect_to :action => 'index', :id => @project
    else
      render :action => "new"
    end
  end

  def update
    if @payment.update_attributes(params[:payment])
      flash[:notice] = 'Payment was successfully updated.'
      redirect_to :action => 'index', :id => @project
    else
      render :action => "edit"
    end
  end

  def destroy
    @payment.destroy
    redirect_to :action => 'index', :id => @project
  end

  private

  def find_project
    begin
      @project = Project.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end
  end

  def find_payment
    @payment = Payment.find(params[:id])
    @project = @payment.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
