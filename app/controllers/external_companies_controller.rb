class ExternalCompaniesController < ApplicationController
  unloadable

  layout 'admin'
  menu_item :external_companies
  before_filter :require_admin

  def index
    @ecompanies = ExternalCompany.all
  end

  def new
    @ecompany = ExternalCompany.new
  end

  def create
    @ecompany = ExternalCompany.new(params[:external_company])
    if @ecompany.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action=>'index'
    else
      render :action => 'new'
    end
  end

  def edit
    @ecompany = ExternalCompany.find(params[:id])
  end

  def update
    @ecompany = ExternalCompany.find(params[:id])
    if @ecompany.update_attributes(params[:external_company])
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'index'
    else
      render :action => 'edit'
    end
  end

  def destroy
    @ecompany = ExternalCompany.find(params[:id])
    @ecompany.destroy
    redirect_to :action => 'index'
  end
end
