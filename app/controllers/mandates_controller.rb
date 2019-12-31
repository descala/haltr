class MandatesController < ApplicationController


  menu_item Haltr::MenuItem.new(:payments,:mandates)
  layout 'haltr'
  helper :haltr
  before_action :find_project_by_project_id
  before_action :find_mandate, :only => [:show,:edit,:update,:destroy,:signed_doc]
  before_action :authorize
  include CompanyFilter
  before_action :check_for_company

  def index
    @mandates = @project.mandates.order("created_at desc")
  end

  def show
    @company = @project.company
    @client = @mandate.client
    @is_pdf = false
    respond_to do |format|
      format.html
      format.pdf do
        @is_pdf = true
        render :pdf => "mandate_#{@mandate.id}",
          :disposition => 'attachment',
          :layout => "mandate.html",
          :template=>"mandates/show",
          :formats => :html,
          :show_as_html => params[:debug]
      end
    end
  end

  def new
    @mandate = Mandate.new
  end

  def create
    @mandate = Mandate.new(params[:mandate])
    respond_to do |format|
      if @mandate.save
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_to project_mandates_path(@project)
        }
        format.js
      else
        format.html { render :action => 'new' }
        format.js { render :action => 'create_error' }
      end
    end
  end

  def edit
  end

  def update
    if @mandate.update_attributes(params[:mandate])
      flash[:notice] = l(:notice_successful_update)
      redirect_to project_mandates_path(@project)
    else
      render :action => "edit"
    end
  end

  def destroy
    @mandate.destroy
    redirect_to project_mandates_path(@project)
  end

  def signed_doc
    if @mandate.signed_doc
      send_data @mandate.signed_doc,
        :type => 'application/pdf',
        :filename => "mandate_signed_#{@mandate.id}.pdf",
        :disposition => params[:disposition] == 'inline' ? 'inline' : 'attachment'
    else
      flash[:error] = "asd"
    end
  end

  private

  def find_mandate
    @mandate = Mandate.find params[:id]
    @client = @mandate.client
    @project = @client.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
