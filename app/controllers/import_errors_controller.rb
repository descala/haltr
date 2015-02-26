class ImportErrorsController < ApplicationController

  unloadable
  menu_item Haltr::MenuItem.new(:invoices,:import_errors)
  helper :haltr
  helper :invoices
  layout 'haltr'
  before_filter :find_project_by_project_id
  before_filter :authorize

  def index
    @import_errors = @project.import_errors.order('created_at desc')
  end

  def show
    import_error = @project.import_errors.find(params[:id])
    send_data import_error.original,
      :type => 'text/xml; charset=UTF-8;',
      :disposition => "attachment; filename=#{import_error.filename}"
  end

  def destroy
    import_error = @project.import_errors.find(params[:id])
    import_error.destroy
    redirect_to action: :index
  end

end
