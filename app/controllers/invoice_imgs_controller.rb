class InvoiceImgsController < ApplicationController
  unloadable

  before_filter :find_project_by_project_id

  def show
    send_data(Haltr::Utils.decompress(InvoiceImg.find(params[:id]).img),
              type: 'image/png',
              disposition: 'inline')
  end

end
