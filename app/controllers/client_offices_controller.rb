class ClientOfficesController < ApplicationController

  unloadable
  menu_item Haltr::MenuItem.new(:companies,:client_offices)

  layout 'haltr'
  helper :haltr

  helper :sort
  include SortHelper

  before_filter :find_client

  include CompanyFilter
  before_filter :check_for_company

  def index
    sort_init 'name', 'asc'
    sort_update %w(name city)

    client_offices = @client.nil? ? @project.client_offices.scoped :  @client.client_offices.scoped

    unless params[:name].blank?
      name = "%#{params[:name].strip.downcase}%"
      client_offices = client_offices.scoped :conditions => ["LOWER(client_offices.name) LIKE ? OR LOWER(client_offices.city) LIKE ? OR LOWER(client_offices.province) LIKE ?", name, name, name]
    end

    @client_office_count = client_offices.count
    @client_office_pages = Paginator.new self, @client_office_count,
		per_page_option,
		params['page']
    @client_offices = client_offices.find :all,
       :order => sort_clause,
       :limit  => @client_office_pages.items_per_page,
       :offset => @client_office_pages.current.offset
  end

  def new
    @client_office = ClientOffice.new(
      # fill with client data
      Hash[%w(address address2 city province postalcode country email).map {|sym| [sym, @client[sym]]}]
    )
    @client_office.client = @client
  end

  def create
    @client_office = ClientOffice.new(params[:client_office])
    @client_office.client = @client
    if @client_office.save
      redirect_to client_client_offices_path(@client), notice: l(:notice_successful_create)
    else
      render action: :new
    end
  end

  def edit
    @client_office = @client.client_offices.find(params[:id])
  end

  def update
    @client_office = @client.client_offices.find(params[:id])
    if @client_office.update_attributes(params[:client_office])
      redirect_to client_client_offices_path(@client), notice: l(:notice_successful_update)
    else
      render action: :edit
    end
  end

  def destroy
    @client.client_offices.find(params[:id]).destroy rescue nil
    redirect_to client_client_offices_path(@client)
  end

  private

  def find_client
    if params.has_key? :client_id
      @client = Client.find params[:client_id]
      @project = @client.project
    else
      @project = Project.find params[:project_id]
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
