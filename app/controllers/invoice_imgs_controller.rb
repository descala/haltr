class InvoiceImgsController < ApplicationController
  unloadable

  before_filter :find_project_by_project_id, :except => [:create]
  skip_before_filter :check_if_login_required, :only => [:create]
  before_filter :check_remote_ip,              :only => [:create]

  def show
    send_data(Haltr::Utils.decompress(InvoiceImg.find(params[:id]).img),
              type: 'image/png',
              disposition: 'inline')
  end

  def create
    @invoice_img = InvoiceImg.new(params[:invoice_img])
    respond_to do |format|
      if @invoice_img.save
        format.xml  { render :xml  => @invoice_img, :status => :created }
        format.json { render :json => @invoice_img, :status => :created }
      else
        format.xml  { render :xml  => @invoice_img.errors, :status => :unprocessable_entity }
        format.json { render :json => @invoice_img.errors, :status => :unprocessable_entity }
      end
    end
  end

  #TODO: duplicated code
  def check_remote_ip
    allowed_ips = Setting.plugin_haltr['b2brouter_ip'].gsub(/ /,'').split(",") << "127.0.0.1"
    unless allowed_ips.include?(request.remote_ip) or %w(test development).include?(Rails.env)
      render :text => "Not allowed from your IP #{request.remote_ip}\n", :status => 403
      logger.error "Not allowed from IP #{request.remote_ip} (allowed IPs: #{allowed_ips.join(', ')})\n"
      return false
    end
  end

end
