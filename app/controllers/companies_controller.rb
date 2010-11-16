class CompaniesController < ApplicationController

  unloadable
  menu_item :haltr

  before_filter :find_project, :except => [:update]
  before_filter :find_company, :only => [:update]
  before_filter :authorize

  include CompanyFilter
  before_filter :check_for_company

  def index
    @company = @project.company
    render :action => 'edit'
  end

  def update
    if @company.update_attributes(params[:company])
      flash[:notice] = 'Settings successfully updated'
      redirect_to :action => 'index', :id => @project
    else
      render :action => 'edit'
    end
  end

  private

  def find_company
    @company = Company.find params[:id]
    @project = @company.project
  end

end
