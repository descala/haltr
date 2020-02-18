class PeopleController < ApplicationController


  menu_item Haltr::MenuItem.new(:companies,:people)
  layout 'haltr'
  helper :haltr
  helper :sort
  include SortHelper

  before_action :find_optional_client, :only => [:index]
  before_action :find_client, :only => [:new,:create]
  before_action :find_person, :only => [:show,:edit,:destroy,:update]
  before_action :authorize

  include CompanyFilter
  before_action :check_for_company

  def index
    sort_init 'last_name', 'asc'
    sort_update %w(first_name last_name email)

    people = @client.nil? ? @project.people :  @client.people

    unless params[:name].blank?
      name = "%#{params[:name].strip.downcase}%"
      people = people.where(["LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ? OR LOWER(people.email) LIKE ?", name, name, name])
    end

    @person_count = people.count
    @person_pages = Paginator.new @person_count,
		per_page_option,
		params['page']
    @people = people.order(sort_clause).limit(@person_pages.items_per_page).offset(@person_pages.current.offset)
  end

  def show
  end

  def new
    @person = Person.new
  end

  def edit
  end

  def create
    @person = Person.new
    @person.safe_attributes = params[:person].merge({client:@client})
    if @person.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'index', :id => @client
    else
      render :action => "new"
    end
  end

  def update
    @person.safe_attributes = params[:person]
    if @person.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'index', :client_id => @person.client
    else
      render :action => "edit"
    end
  end

  def destroy
    @person.destroy
    redirect_to :action => 'index', :client_id => @person.client
  end

  private

  def find_optional_client
    @client = Client.find params[:client_id] unless params[:client_id].blank?
    if @client
      @project = @client.project
    else 
      @project = Project.find(params[:project_id])
    end
    rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_client
    @client = Client.find params[:client_id]
    @project = @client.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_person
    @person = Person.find(params[:id])
    @client = @person.client
    @project = @client.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
