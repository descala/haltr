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

  accept_api_auth :create, :show, :index, :destroy

  include CompanyFilter
  before_filter :check_for_company

  def index
    sort_init 'name', 'asc'
    sort_update %w(taxcode name)

    clients = @project.clients.scoped

    unless params[:name].blank?
      name = "%#{params[:name].strip.downcase}%"
      clients = clients.scoped :conditions => ["LOWER(name) LIKE ? OR LOWER(address) LIKE ? OR LOWER(address2) LIKE ? OR LOWER(taxcode) LIKE ?", name, name, name, name]
    end

    case params[:format]
    when 'xml', 'json'
      @offset, @limit = api_offset_and_limit
    else
      @limit = per_page_option
    end

    @client_count = clients.count
    @client_pages = Paginator.new self, @client_count, @limit, params['page']
    @offset ||= @client_pages.offset
    @clients =  clients.find :all,
       :order => sort_clause,
       :limit  =>  @limit,
       :offset =>  @offset
  end

  # Only used in API
  def show
    respond_to do |format|
      format.api
    end
  end

  def new
    @client = Client.new(:country=>@project.company.country,
                         :currency=>@project.company.currency,
                         :language=>User.current.language)
  end

  def edit
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
        format.api { render :action => 'show', :status => :created, :location => client_url(@client) }
      else
        format.html { render :action => 'new' }
        format.js   { render :action => 'create_error' }
        format.api  { render_validation_errors(@client) }
      end
    end
  end

  def update
    if @client.update_attributes(params[:client])
      event = Event.new(:name=>'edited',:client=>@client,:user=>User.current)
      # associate last created audits to this event
      event.audits = @client.last_audits_without_event
      event.save!
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'index', :project_id => @project
    else
      render :action => "edit"
    end
  end

  def destroy
    @client.destroy
    event = EventDestroy.new(:name    => "deleted_client",
                             :notes   => @client.name,
                             :project => @client.project)
    event.audits = @client.last_audits_without_event
    event.save!
    respond_to do |format|
      format.html { redirect_back_or_default project_clients_path(@project) }
      format.api  { render_api_ok }
    end
  end

  def check_cif
    if params[:value]
      taxcode = params[:value].encode(
        'UTF-8', 'binary', invalid: :replace, undef: :replace, replace: ''
      ).gsub(/\W/,'').downcase
      if taxcode[0...2].downcase == @project.company.country
        taxcode2 = taxcode[2..-1]
      else
        taxcode2 = "#{@project.company.country}#{taxcode}"
      end
    end
    # the client we are editing (or nil if creating new one)
    client = Client.find(params[:client]) unless params[:client].blank?
    # search for an existing client with the specified taxcode
    existing_client = @project.clients.collect {|c|
      c if [taxcode, taxcode2].include? c.taxcode.to_s.downcase
    }.compact.first
    # check if we are editing or creating a client and entered a taxcode that
    # already exists on another of our clients
    if existing_client and (( client and client.id != existing_client.id ) or !client )
      # render nothing, activerecord validations will raise an error
      render :partial => 'cif_info', :locals => {:client=>nil,:company=>nil}
    else
      # we are creating/editing a new client
      # search a company with specified taxcode and (semi)public profile
      company = Company.where(
        "taxcode in (?, ?) and (public='public' or public='semipublic')", taxcode, taxcode2
      ).first
      company ||= ExternalCompany.where("taxcode in (?, ?)", taxcode, taxcode2).first
      render :partial => "cif_info", :locals => { :client => client,
                                                  :company => company,
                                                  :context => params[:context],
                                                  :invoice_id => params[:invoice_id] }
    end
  end

  def link_to_profile
    taxcode = params[:company]
    if taxcode[0...2].downcase == @project.company.country
      taxcode2 = taxcode[2..-1]
    else
      taxcode2 = "#{@project.company.country}#{taxcode}"
    end
    # ExternalCompany has priority over Company
    @company = ExternalCompany.where("taxcode in (?, ?)", taxcode, taxcode2).first
    @company ||= Company.where(
      "taxcode in (?, ?) and (public='public' or public='semipublic')", taxcode, taxcode2
    ).first
    @client    = Client.find(params[:client]) unless params[:client].blank?
    @client  ||= Client.new(:project=>@project)
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
    req = Company.find params[:req]
    req.project.clients.where("company_id=?", @project.company.id).each do |client|
      client.allowed = true
      client.save
    end
    redirect_to :action => 'index', :project_id => @project
  end

  def deny_link
    req = Company.find params[:req]
    req.project.clients.where("company_id=?", @project.company.id).each do |client|
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
