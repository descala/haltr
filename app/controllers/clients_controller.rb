class ClientsController < ApplicationController

  unloadable

  menu_item Haltr::MenuItem.new(:companies,:companies_level2)

  layout 'haltr'
  helper :haltr, :invoices

  helper :sort
  include SortHelper

  before_filter :find_project_by_project_id, :only => [:index,:new,:create,:ccc2iban]
  before_filter :find_project,  :only => [:link_to_profile,:allow_link,:deny_link,:check_cif]
  before_filter :find_client, :except => [:index,:new,:create,:link_to_profile,:allow_link,:deny_link,:check_cif,:ccc2iban]
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
    @client = Client.new(:country=>@project.company.country,
                         :currency=>@project.company.currency)
  end

  def edit
    @company = Company.find(:all, :conditions => ["taxcode = ? and (public='public' or public='semipublic')", @client.taxcode]).first
  end

  def create
    @client = Client.new(params[:client].merge({:project=>@project}))
    respond_to do |format|
      if @client.save
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_to :action=>'index', :project_id=>@project
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
      redirect_to :action => 'index', :project_id => @project
    else
      render :action => "edit"
    end
  end

  def destroy
    @client.destroy
    redirect_to :action => 'index', :project_id => @project
  end

  def check_cif
    taxcode = params[:value].gsub(/\W/,'').downcase if params[:value]
    # the client we are editing (or nil if creating new one)
    client = Client.find(params[:client]) unless params[:client].blank?
    # search for an existing client with the specified taxcode
    existing_client = @project.clients.collect {|c|
      c if c.taxcode.to_s.downcase == taxcode
    }.compact.first
    # check if we are editing or creating a client and entered a taxcode that
    # already exists on another of our clients
    if existing_client and (( client and client.id != existing_client.id ) or !client )
      # render nothing, activerecord validations will raise an error
      render :partial => 'cif_info', :locals => {:client=>nil,:company=>nil}
    else
      # we are creating/editing a new client
      # search a company with specified taxcode and (semi)public profile
      company = Company.find(:all,
                  :conditions => ["taxcode = ? and (public='public' or public='semipublic')", taxcode]).first
      render :partial => "cif_info", :locals => { :client => client,
                                                  :company => company,
                                                  :context => params[:context],
                                                  :invoice_id => params[:invoice_id] }
    end
  end

  def link_to_profile
    @company = Company.find(params[:company])
    @client = Client.find(params[:client]) unless params[:client].blank?
    @client ||= Client.new(:project=>@project)
    @client.company = @company
    @client.taxcode = @company.taxcode
    if @client.save
      case params[:context]
      when "new_invoice" then
        redirect_to project_client_new_invoice_path(:project_id=>@project.id,
                                                    :client=>@client.id)
      when "edit_invoice" then
        if params[:invoice_id]
          redirect_to edit_invoice_path(params[:invoice_id],
                                        :created_client_id=>@client.id)
        else
          redirect_to project_invoices_path(:project_id=>@project.id)
        end
      else
        redirect_to :action => 'edit', :id => @client
      end
    else
      @client.company = nil
      render :action => 'new'
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
    unless @project.company.taxcode.blank?
      req = Company.find params[:req]
      client = req.project.clients.find_by_taxcode(@project.company.taxcode)
      client.allowed = true
      client.save
    end
    redirect_to :action => 'index', :project_id => @project
  end

  def deny_link
    unless @project.company.taxcode.blank?
      req = Company.find params[:req]
      client = req.project.clients.find_by_taxcode(@project.company.taxcode)
      client.allowed = false
      client.save
    end
    redirect_to :action => 'index', :project_id => @project
  end

  def ccc2iban
    ccc=params[:ccc].try(:gsub,/\p{^Alnum}/, '')
    iban=""
    if BankInfo.valid_spanish_ccc?(ccc)
      iban=BankInfo.local2iban('ES',ccc)
    end
    render :text => iban
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
