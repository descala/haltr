class ExternalCompaniesController < ApplicationController
  unloadable

  layout 'admin'
  menu_item :external_companies
  before_filter :authorize_global
  helper :haltr

  include CsvImporter

  def index
    @ecompanies = ExternalCompany.all(order: :name)
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

  def csv_import
    file = params[:csv_file]
    if file and file.size > 0
      existing, new, error, error_messages = process_external_companies(external_companies: file.path)
      flash[:notice] = "External Companies updated: #{existing}, created: #{new}, errors: #{error}. #{error_messages.join(', ')}"
    else
      flash[:error] = "Select a CSV file to import"
    end
    redirect_to action: 'index'
  end

end
