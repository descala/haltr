class CompanyOfficesController < ApplicationController

  menu_item Haltr::MenuItem.new(:my_company, :company_offices)

  layout 'haltr'
  helper :haltr

  helper :sort
  include SortHelper

  before_filter :find_company

  include CompanyFilter
  before_filter :check_for_company

  before_filter :authorize

  def index
    sort_init 'city', 'asc'
    sort_update %w(city)

    company_offices = @company.company_offices

    unless params[:name].blank?
      name = "%#{params[:name].strip.downcase}%"
      company_offices = company_offices.where(["LOWER(company_offices.city) LIKE ? OR LOWER(company_offices.province) LIKE ?", name, name])
    end

    @limit = per_page_option
    @company_office_count = company_offices.count
    @company_office_pages = Paginator.new @company_office_count, @limit, params['page']
    @offset ||= @company_office_pages.offset
    @company_offices = company_offices.order(sort_clause).limit(@limit).offset(@offset).to_a
  end

  def new
    @company_office = CompanyOffice.new(
      # fill with company data
      Hash[CompanyOffice::COMPANY_FIELDS.map {|sym| [sym, @company[sym]]}]
    )
    @company_office.company = @company
  end

  def create
    @company_office = CompanyOffice.new(params[:company_office])
    @company_office.company = @company
    if @company_office.save
      redirect_to project_company_offices_path(project_id: @project), notice: l(:notice_successful_create)
    else
      render action: :new
    end
  end

  def edit
    @company_office = @company.company_offices.find(params[:id])
  end

  def update
    @company_office = @company.company_offices.find(params[:id])
    if @company_office.update_attributes(params[:company_office])
      redirect_to project_company_offices_path(project_id: @project), notice: l(:notice_successful_update)
    else
      render action: :edit
    end
  end

  def destroy
    @company.company_offices.find(params[:id]).destroy rescue nil
    redirect_to project_company_offices_path(project_id: @project)
  end

  private

  def find_company
    @project = Project.find params[:project_id]
    @company = @project.company
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
