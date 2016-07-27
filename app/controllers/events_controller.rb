class EventsController < ApplicationController

  helper :haltr

  skip_before_filter :check_if_login_required, :only => [ :create, :file ]
  before_filter :check_remote_ip, :except => [:file, :index]
  before_filter :find_event, :only => [:file]
  before_filter :find_project_by_project_id, :only => [:index]
  before_filter :authorize, :only => [:index]
  before_filter :authorize_or_find_hashid, only: [:file]

  accept_api_auth :file, :index

  helper :sort
  include SortHelper

  def index
    sort_init   'created_at', 'desc'
    sort_update %w(created_at type)

    if @project
      events = Event.where(project_id: @project.id)
    else
      events = Event.scoped
    end

    if params[:from_time].present?
      events = events.where('created_at >= ?', params[:from_time])
    end

    if params[:to_time].present?
      events = events.where('created_at <= ?', params[:to_time].to_date.end_of_day)
    end

    if params[:invoice_id].present?
      events = events.where('invoice_id = ?', params[:invoice_id])
    end

    unless User.current.admin?
      events = events.where("type!='HiddenEvent'")
    end

    case params[:format]
    when 'xml', 'json'
      @offset, @limit = api_offset_and_limit
    else
      @limit = per_page_option
    end

    @event_count = events.count
    @event_pages = Paginator.new self, @event_count, @limit, params['page']
    @offset ||= @event_pages.offset
    @events =  events.find :all,
      :order   => sort_clause,
      :include => [:invoice],
      :limit   => @event_pages.items_per_page,
      :offset  => @offset

    respond_to do |format|
      format.html do
      end
      format.api do
      end
    end
  end

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
      end
    end

    respond_to do |format|
      if @event.save
        flash[:notice] = 'Event was successfully created.'
        format.xml  { render :xml => @event, :status => :created }
        format.json  { render :json => @event, :status => :created }
      else
        format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
        format.json { render :json => @event.errors, :status => :unprocessable_entity }
      end
    end
  end

  def file
    file_field         = params[:file]         || 'file'
    filename_field     = params[:filename]     || 'filename'
    content_type_field = params[:content_type] || 'content_type'
    data               = @event.try(file_field)         rescue nil
    filename           = @event.try(filename_field)     rescue nil
    content_type       = @event.try(content_type_field) rescue nil
    if data
      unless content_type # try to guess content_type
        begin
          tf = Tempfile.new('')
          tf.binmode
          tf.write(data)
          tf.close
          content_type = IO.popen(['file', '--brief', '--mime-type', tf.path],
                                  :in => :close, :err => :close) {|io| io.read.chomp }
          tf.unlink
        rescue
          content_type = ""
        end
      end
      unless filename # try to guess filename
        require "mime/types"
        ext = MIME::Types[content_type].first.extensions.first rescue nil
        filename = "#{@event.id}.#{ext}" if ext
      end
      send_data data, :filename => filename, :content_type => content_type
    else
      render_404
    end
  end

  private

  def find_event
    @event = Event.find params[:id]
    @project = @event.project
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

  # on invoice#view we need to access events files to show them in pdf viewer
  # authenticate with client_hashid
  def authorize_or_find_hashid
    client = Client.find_by_hashid params[:client_hashid]
    unless client and client.project.events.find(params[:id])
      authorize
      return
    end
  end

end
