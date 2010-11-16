class ClientsController < ApplicationController

  unloadable

  menu_item :haltr

  helper :sort
  include SortHelper

  before_filter :find_project, :only => [:index,:new,:create]
  before_filter :find_client, :except => [:index,:new,:create]
  before_filter :authorize

  include CompanyFilter
  before_filter :check_for_company

  def index
    sort_init 'taxcode', 'asc'
    sort_update %w(taxcode name)

    c = ARCondition.new(["project_id = ?", @project])

    unless params[:name].blank?
      name = "%#{params[:name].strip.downcase}%"
      c << ["LOWER(name) LIKE ? OR LOWER(address1) LIKE ? OR LOWER(address2) LIKE ?", name, name, name]
    end

    @client_count = Client.count(:conditions => c.conditions)
    @client_pages = Paginator.new self, @client_count,
		per_page_option,
		params['page']
    @clients =  Client.find :all,:order => sort_clause,
       :conditions => c.conditions,
       :limit  =>  @client_pages.items_per_page,
       :offset =>  @client_pages.current.offset

    render :action => "index", :layout => false if request.xhr?
  end

  def new
    @client = Client.new
  end

  def edit
    @client = Client.find(params[:id])
  end

  def create
    @client = Client.new(params[:client].merge({:project=>@project}))
    if @client.save
      flash[:notice] = 'Client was successfully created.'
      redirect_to :action => 'index', :id => @project
    else
      render :action => "new"
    end
  end

  def update
    if @client.update_attributes(params[:client])
      flash[:notice] = 'Client was successfully updated.'
      redirect_to :action => 'index', :id => @project
    else
      render :action => "edit"
    end
  end

  def destroy
    @client.destroy
    redirect_to :action => 'index', :id => @project
  end

  private

  def find_client
    @client = Client.find params[:id]
    @project = @client.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end


end
