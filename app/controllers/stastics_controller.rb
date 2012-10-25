class StasticsController < ApplicationController

  unloadable
  layout 'admin'
  helper :haltr
  helper :sort
  include SortHelper

  before_filter :require_admin

  def index
    sort_init 'name', 'invoices_count'
    sort_update %w(name invoices_count issued_invoices_count received_invoices_count invoice_templates_count)

    projects = Project.active.scoped :conditions => ["invoices_count >= ?", params[:invoices_min].blank? ? 1 : params[:invoices_min]]

    @projects_count = projects.count
    @projects_pages = Paginator.new self, @projects_count, per_page_option, params['page']
    @projects = projects.find :all,
      :order => sort_clause,
      :limit => @projects_pages.items_per_page,
      :offset => @projects_pages.current.offset

    render :action => "index"
  end

end
