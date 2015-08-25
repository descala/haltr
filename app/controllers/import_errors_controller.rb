class ImportErrorsController < ApplicationController

  unloadable
  menu_item Haltr::MenuItem.new(:invoices,:import_errors)
  helper :haltr
  layout 'haltr'
  before_filter :find_project_by_project_id, only: [:index, :show, :create]
  before_filter :find_import_errors, :only => [:context_menu, :destroy]
  before_filter :authorize

  accept_api_auth :create, :index

  helper :context_menus
  helper :sort
  include SortHelper

  def index
    sort_init 'created_at', 'desc'
    sort_update %w(created_at filename import_errors)

    import_errors = @project.import_errors.scoped

    @import_errors_count = import_errors.count
    @import_errors_pages = Paginator.new self, @import_errors_count,
      per_page_option, params[:page]
    @import_errors = import_errors.all(
      order:  sort_clause,
      limit:  @import_errors_pages.items_per_page,
      offset: @import_errors_pages.current.offset
    )
  end

  def show
    import_error = @project.import_errors.find(params[:id])
    send_data import_error.original,
      :type => 'text/xml; charset=UTF-8;',
      :disposition => "attachment; filename=#{import_error.filename}"
  end

  def create
    @import_error = ImportError.new(params[:import_error])
    if @import_error.save!
      respond_to do |format|
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.api { render_validation_errors(@import_error) }
      end
    end
  end

  def destroy
    @import_errors.each do |import_error|
      begin
        import_error.reload.destroy
      rescue ::ActiveRecord::RecordNotFound
      end
    end
    redirect_to action: :index
  end

  # see redmine's context_menu controller
  def context_menu
    (render_404; return) unless @import_errors.present?
    if (@import_errors.size == 1)
      @import_error = @import_errors.first
    end
    @import_error_ids = @import_errors.map(&:id).sort

    @can = { :edit => User.current.allowed_to?(:import_invoices, @project) }
    @back = back_url

    render :layout => false
  end

  def find_import_errors
    @import_errors = ImportError.find_all_by_id(params[:id] || params[:ids])
    raise ActiveRecord::RecordNotFound if @import_errors.empty?
    raise Unauthorized unless @import_errors.collect {|i| i.project }.uniq.size == 1
    @project = @import_errors.first.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
