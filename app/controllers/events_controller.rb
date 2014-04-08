class EventsController < ApplicationController
  unloadable
  helper :haltr

  skip_before_filter :check_if_login_required, :only => [ :create ]
  before_filter :check_remote_ip, :except => [:file]

  def create
    t = params[:event][:type]
    if t =~ /Event/
      @event = t.constantize.new(params[:event])
    elsif t.blank?
      @event = Event.new(params[:event])
    else
      #TODO raise / log
    end

    #TODO: should remove this when all events come with type
    if @event.type == 'Event'
      @event.type = 'ReceivedInvoiceEvent' if @event.name == 'email'
      if @event.md5.blank?
        @event.type = 'EventWithMail' if @event.name =~ /paid_notification$/
      else
        invoice_format = @event.invoice.client.invoice_format rescue ""
        if ( invoice_format == "facturae_32_face" )
          @event.type = 'EventWithUrlFace'
        else
          @event.type = 'EventWithUrl'
        end
      end
    end

    respond_to do |format|
      if @event.save
        flash[:notice] = 'Event was successfully created.'
        format.xml  { render :xml => @event, :status => :created, :location => @event }
      else
        format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
      end
    end
  end

  def file
    event = Event.find params[:id]
    send_data event.file, :filename => event.filename, :type => event.content_type
  end


  private

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
