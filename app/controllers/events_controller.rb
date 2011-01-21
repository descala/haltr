class EventsController < ApplicationController
  unloadable

  skip_before_filter :check_if_login_required, :only => [ :create ]
  before_filter :check_remote_ip, :find_invoice

  def create
    @event = Event.new(params[:event])
    @event.invoice = @invoice
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

  def check_remote_ip
    unless request.remote_ip == '127.0.0.1' #TODO: or Setting.plugin_haltr['b2brouter_ip'].gsub(/ /,'').split(",").include?(request.remote_ip)
      render :text => "Not allowed from your IP #{request.remote_ip}\n", :status => 403
      logger.error "Not allowed from IP #{request.remote_ip}\n" #TODO: (must be from #{Setting.plugin_haltr['b2brouter_ip']}).\n"
      return false
    end
  end

  def find_invoice
    @invoice = InvoiceDocument.find params[:invoice_id]
  end

end
