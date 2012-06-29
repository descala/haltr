class EventsController < ApplicationController
  unloadable
  helper :haltr

  skip_before_filter :check_if_login_required, :only => [ :create ]
  before_filter :check_remote_ip

  verify :method => :post, :only => [:create], :redirect_to => :root_path

  def create
    @event = Event.new(params[:event])
    respond_to do |format|
      if @event.save
        flash[:notice] = 'Event was successfully created.'
        format.xml  { render :xml => @event, :status => :created, :location => @event }
      else
        format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
      end
    end
  end


  private

  #TODO: duplicated code
  def check_remote_ip
    allowed_ips = Setting.plugin_haltr['b2brouter_ip'].gsub(/ /,'').split(",") << "127.0.0.1"
    unless allowed_ips.include?(request.remote_ip)
      render :text => "Not allowed from your IP #{request.remote_ip}\n", :status => 403
      logger.error "Not allowed from IP #{request.remote_ip} (allowed IPs: #{allowed_ips.join(', ')})\n"
      return false
    end
  end

end
