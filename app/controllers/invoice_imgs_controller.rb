class InvoiceImgsController < ApplicationController

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
    byebug
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
    text = params[:token_ids].collect do |token_id|
      @invoice_img.tokens[token_id.to_i][:text] rescue nil
    end.join(' ')
    @current_tag = @invoice_img.tags_inverted[params[:token_ids].first.to_i]
    tags = []
    if text =~ /[a-zA-Z]/
      tags += [:seller_name, :seller_country]
    end
    tags += [:seller_taxcode]
    if text =~ /\d/
      tags += @invoice_img.all_possible_tags
    end
    @assiged_tags = @invoice_img.tags.keys
    @missing_tags = tags.uniq - @assiged_tags - [:language]
    render :layout => false
  end

  def update
    @invoice_img.all_possible_tags.each do |tag|
      next if params[tag].empty?
      next if @invoice_img.tagv(tag) == params[tag]
      token_number = @invoice_img.tags[tag]
      if token_number and @invoice_img.tokens[token_number]
        @invoice_img.tokens[token_number][:text] = params[tag]
      else
        @invoice_img.tags[tag] = params[tag]
      end
    end
    @invoice_img.update_invoice
    redirect_back_or_default(:controller=>'received',:action=>'show',:id=>@invoice_img.invoice.id)
  end

  def tag
    if params[:token_ids].nil?
      # clear tag
      @invoice_img.tags.delete(params['tag'].to_sym)
    else
      if params[:token_ids].size == 1
        @invoice_img.tags[params['tag'].to_sym] = params[:token_ids].first.to_i
      else
        @invoice_img.tags[params['tag'].to_sym] = params[:token_ids].collect{|n|n.to_i}
      end
    end
    @invoice_img.update_invoice
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
