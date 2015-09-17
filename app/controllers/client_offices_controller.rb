class ClientOfficesController < ApplicationController

  unloadable
  menu_item Haltr::MenuItem.new(:companies,:client_offices)

  layout 'haltr'
  helper :haltr

  before_filter :find_client
  before_filter :authorize

  include CompanyFilter
  before_filter :check_for_company

  def index
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
    @client = Client.find params[:client_id]
    @project = @client.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
