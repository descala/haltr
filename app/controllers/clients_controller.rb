class ClientsController < ApplicationController

  unloadable

  menu_item :haltr_community
  layout 'haltr'
  helper :haltr, :invoices

  helper :sort
  include SortHelper

  before_filter :find_project,  :only => [:index,:new,:create,:check_cif,:link_to_profile,:allow_link,:deny_link]
  before_filter :find_client, :except => [:index,:new,:create,:check_cif,:link_to_profile,:allow_link,:deny_link]
  before_filter :set_iso_countries_language
  before_filter :authorize

  include CompanyFilter
  before_filter :check_for_company

  def index
    sort_init 'name', 'asc'
    sort_update %w(taxcode name)

    clients = @project.clients.scoped

    unless params[:name].blank?
      name = "%#{params[:name].strip.downcase}%"
      clients = clients.scoped :conditions => ["LOWER(name) LIKE ? OR LOWER(address) LIKE ? OR LOWER(address2) LIKE ?", name, name, name]
    end

    @client_count = clients.count
    @client_pages = Paginator.new self, @client_count,
		per_page_option,
		params['page']
    @clients =  clients.find :all,
       :order => sort_clause,
       :limit  =>  @client_pages.items_per_page,
       :offset =>  @client_pages.current.offset
  end

  def new
    @client = Client.new
  end

  def edit
    @client = Client.find(params[:id])
    @company = Company.find(:all, :conditions => ["taxcode = ? and (public='public' or public='semipublic')", @client.taxcode]).first
  end

  def create
    @new_client = Client.new(params[:client].merge({:project=>@project}))
    respond_to do |format|
      if @new_client.save
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_to :controller=>'clients', :action=>'index', :id=>@project
        }
        format.js
      else
        format.html { render :action => 'new' }
        format.js  { render :action => 'create_error' }
      end
    end
  end

  def update
    if @client.update_attributes(params[:client])
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'index', :id => @project
    else
      render :action => "edit"
    end
  end

  def destroy
    @client.destroy
    redirect_to :action => 'index', :id => @project
  end

  def check_cif
    taxcode = params[:value].gsub(/\W/,'')
    company = Company.find(:all, :conditions => ["taxcode = ? and (public='public' or public='semipublic')", taxcode]).first
    client = Client.find(params[:client]) unless params[:client].blank?
    render :partial => "cif_info", :locals => { :client => client, :company => company }
  end

  def link_to_profile
    @company = Company.find(params[:company])
    @client = Client.find(params[:client]) unless params[:client].blank?
    @client ||= Client.new(:project=>@project)
    @client.company = @company
    @client.taxcode = @company.taxcode
    if @client.save
      redirect_to :action => 'edit', :id => @client
    else
      @client.company = nil
      render :action => 'edit'
    end
  end

  def unlink
    @company = @client.company
    @client.company=nil
    @client.allowed=nil
    @client.save(:validate=>false)
    redirect_to :action => 'edit', :id => @client
  end

  def allow_link
    req = Company.find params[:req]
    client = req.project.clients.find_by_taxcode(@project.company.taxcode)
    client.allowed = true
    client.save
    redirect_to :action => 'index', :id => @project
  end

  def deny_link
    req = Company.find params[:req]
    client = req.project.clients.find_by_taxcode(@project.company.taxcode)
    client.allowed = false
    client.save
    redirect_to :action => 'index', :id => @project
  end

  private

  def find_client
    @client = Client.find params[:id]
    @project = @client.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def set_iso_countries_language
    ISO::Countries.set_language I18n.locale.to_s
  end

end
