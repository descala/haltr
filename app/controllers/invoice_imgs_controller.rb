class InvoiceImgsController < ApplicationController
  unloadable

  before_filter :find_invoice_img, :except => [:create,:show]
  before_filter :find_project_by_project_id, :only=> [:show]
  skip_before_filter :check_if_login_required, :only => [:create]
  before_filter :check_remote_ip,              :only => [:create]
  helper :context_menus

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

  def context_menu
    @token_ids = params[:token_ids]
    @back = back_url
    @tags = %w(seller_taxcode invoice_number)
    render :layout => false
  end

  def tag
    # TODO support more than one token_id per tag
    @invoice_img.tags[params['tag']] = params[:token_ids].first
    @invoice_img.save
    redirect_back_or_default(:controller=>'received',:action=>'index',:project_id=>@project.id)
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

  def find_invoice_img
    @invoice_img = InvoiceImg.find params[:id]
    @invoice = @invoice_img.invoice
    @project = @invoice.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
