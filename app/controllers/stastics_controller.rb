class StasticsController < ApplicationController

  unloadable
  layout 'admin'
  helper :haltr
  helper :sort
  include SortHelper

  before_filter :require_admin
  before_filter :project_patch

  def index
    sort_init 'name', 'invoices_count'
    sort_update %w(name invoices_count issued_invoices_count received_invoices_count invoice_templates_count)

    c = ARCondition.new()

    unless params[:invoices_min].blank?
      c << ["invoices_count >= ?", params[:invoices_min]]
    end

    @projects_count = Project.count(:conditions=>c.conditions)
    @projects_pages = Paginator.new self, @projects_count, per_page_option, params['page']
    @projects = Project.find :all,
      :order => sort_clause,
      :conditions => c.conditions,
      :limit => @projects_pages.items_per_page,
      :offset => @projects_pages.current.offset

    render :action => "index", :layout => false if request.xhr?
  end

  private

  def project_patch
    Project.send(:include, ProjectHaltrPatch) #TODO: perque nomes funciona el primer cop sense aixo?
  end

end
