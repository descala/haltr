class ClientOfficesController < ApplicationController


  menu_item Haltr::MenuItem.new(:companies,:client_offices)

  layout 'haltr'
  helper :haltr

  helper :sort
  include SortHelper

  before_action :find_client

  include CompanyFilter
  before_action :check_for_company

  before_action :authorize

  def index
    sort_init 'name', 'asc'
    sort_update %w(name city)

    client_offices = @client.nil? ? @project.client_offices:  @client.client_offices

    unless params[:name].blank?
      name = "%#{params[:name].strip.downcase}%"
      client_offices = client_offices.where(["LOWER(client_offices.name) LIKE ? OR LOWER(client_offices.city) LIKE ? OR LOWER(client_offices.province) LIKE ?", name, name, name])
    end

    @limit = per_page_option
    @client_office_count = client_offices.count
    @client_office_pages = Paginator.new @client_office_count, @limit, params['page']
    @offset ||= @client_office_pages.offset
    @client_offices = client_offices.order(sort_clause).limit(@limit).offset(@offset).to_a

  end

  def new
    @client_office = ClientOffice.new(
      # fill with client data
      Hash[ClientOffice::CLIENT_FIELDS.map {|sym| [sym, @client[sym]]}]
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
