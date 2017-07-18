class OrdersController < ApplicationController

  menu_item Haltr::MenuItem.new(:orders,:orders_level2)
  menu_item Haltr::MenuItem.new(:orders,:inexistent), :only => [:import]

  before_filter :find_project_by_project_id
  before_filter :find_order, only: [:add_comment, :show, :create_invoice, :accept]
  before_filter :authorize

  helper :sort
  helper :haltr
  layout 'haltr'
  include SortHelper

  accept_api_auth :import

  def index
    sort_init 'num_pedido'
    sort_update %w(num_pedido fecha_pedido lugar_entrega fecha_entrega fecha_documento)

    orders = Order.where(project_id: @project.id)

    # num_pedido filter
    unless params[:num_pedido].blank?
      orders = orders.where('num_pedido like ?', "%#{params[:num_pedido]}%")
    end

    # lugar_entrega filter
    unless params[:lugar_entrega].blank?
      orders = orders.where('lugar_entrega like ?', "%#{params[:lugar_entrega]}%")
    end

    # filename filter
    unless params[:filename].blank?
      orders = orders.where('filename like ?', "%#{params[:filename]}%")
    end

    # fecha_documento filter
    unless params[:fecha_documento].blank?
      orders = orders.where('fecha_documento >= ?', params[:fecha_documento].gsub('-','')[2..-1])
    end
    unless params[:fecha_documento_to].blank?
      orders = orders.where('fecha_documento <= ?', params[:fecha_documento_to].gsub('-','')[2..-1])
    end

    # fecha_pedido filter
    unless params[:fecha_pedido].blank?
      orders = orders.where('fecha_pedido >= ?', params[:fecha_pedido].gsub('-','')[2..-1])
    end
    unless params[:fecha_pedido_to].blank?
      orders = orders.where('fecha_pedido <= ?', params[:fecha_pedido_to].gsub('-','')[2..-1])
    end

    # fecha_entrega filter
    unless params[:fecha_entrega].blank?
      orders = orders.where('fecha_entrega >= ?', params[:fecha_entrega].gsub('-','')[2..-1])
    end
    unless params[:fecha_entrega_to].blank?
      orders = orders.where('fecha_entrega <= ?', params[:fecha_entrega_to].gsub('-','')[2..-1])
    end

    # client filter
    unless params[:client_id].blank?
      orders = orders.where("client_id = ?", params[:client_id])
      @client_id = params[:client_id].to_i rescue nil
    end

    @limit = per_page_option
    @order_count = orders.count
    @order_pages = Paginator.new @order_count, @limit, params['page']
    @offset ||= @order_pages.offset
    @orders = orders.order(sort_clause).limit(@limit).offset(@offset).to_a
  end

  def show
    if params[:download]
      send_data @order.original,
        :type => 'text/plain',
        :disposition => "attachment; filename=#{@order.filename}"
      return
    elsif params[:show_invoice] and @order.xml?
      send_data @order.ubl_invoice,
        type: 'text/plain',
        disposition: "attachment; filename=#{@order.filename}"
      return
    elsif params[:show_response] and @order.xml?
      send_data @order.order_response,
        type: 'text/plain',
        disposition: "attachment; filename=response_#{@order.filename}"
      return
    elsif @order.xml?
      doc  = Nokogiri::XML(@order.original)
      if doc.child and doc.child.name == "StandardBusinessDocument"
        doc = Haltr::Utils.extract_from_sbdh(doc)
      end
      @client_name = doc.xpath(
        "#{Order::XPATHS_ORDER[:buyer]}/#{Order::XPATHS_PARTY[:name]}"
      ).text rescue nil
      xslt = Nokogiri.XSLT(File.open("#{File.dirname(__FILE__)}/../../lib/haltr/xslt/OIOUBL_Order.xsl",'rb'))
      @order_xslt_html = xslt.transform(doc)
    end
    respond_to do |format|
      format.html {
        #HACK: link to client
        # https://groups.google.com/forum/#!topic/nokogiri-talk/LZjW70XpkLc
        if @order.xml? and @order.client
          @client_name ||= @order.client.name
          @order_xslt_html = @order_xslt_html.to_html.gsub(
            @client_name,
            view_context.link_to(@client_name, client_path(@order.client))
          ).html_safe
        elsif @order.xml?
          @order_xslt_html = @order_xslt_html.to_html.html_safe
        end
        render :show
      }
      format.pdf {
        if @order.xml?
          @order_xslt_html = @order_xslt_html.to_html.html_safe
        end
        render pdf: @order.filename,
        template: 'orders/show',
        layout: 'order',
        :show_as_html => params[:debug],
        :margin => {
          :top    => 20,
          :bottom => 20,
          :left   => 30,
          :right  => 20
        }
      }
    end
  end

  def destroy
    order = Order.where(project_id: @project.id).find(params[:id])
    order.events.destroy_all
    order.destroy
    event = EventDestroy.new(:name    => "deleted_order",
                             :notes   => order.num_pedido,
                             :project => order.project)
    event.save!
    redirect_to action: :index
  end

  def import
    if request.post?
      file = params[:file]
      @order = nil
      if file && file.size > 0
        begin
          is_xml = (file.read =~ /^<\?xml/)
        rescue
        ensure
          file.rewind
        end
        if is_xml
          @order = Order.create_from_xml(file, @project)
        else
          @order = Order.create_from_edi(file, @project)
        end
      end
      respond_to do |format|
        format.html {
          redirect_to project_order_path(@order, project_id: @project)
        }
        format.api {
          render action: :show, status: :created, location: project_order_path(@order, project_id: @project)
        }
      end
    end
  rescue StandardError => e
    respond_to do |format|
      format.html {
        flash.now[:error] = e.message
      }
      format.api {
        render text: e.message, status: :unprocessable_entity
      }
    end
  end

  def add_comment
    @comment = Comment.new
    @comment.safe_attributes = params[:comment]
    @comment.author = User.current
    if @order.comments << @comment
      flash[:notice] = l(:label_comment_added)
    end

    redirect_to project_order_path(@order, project_id: @order.project)
  end

  def create_invoice
    if @order.invoice
      raise "Order already has an invoice: #{@order.invoice.number}"
    end
    invoice_xml = @order.ubl_invoice
    invoice = Invoice.create_from_xml(
      invoice_xml,
      @order.project.company,
      Digest::MD5.hexdigest(invoice_xml),
      'api'
    )
    @order.update_attribute(:invoice_id, invoice.id)
    redirect_to invoice_path(invoice)
  rescue
    flash[:error] = $!.message
    redirect_to action: :show, id: @order
  end

  def accept
    client = @order.client
    if client.schemeid.blank? or client.endpointid.blank?
      flash[:error]="client has no peppol data configured"
      redirect_to project_order_path @order, project_id: @project
      return
    end
    participantIdentifier = "#{B2b::Peppol.sch2iso client.schemeid}:#{client.endpointid}"
    format = ExportFormats.available["peppol_order_response"]
    begin
      # check if client can receive OrderResponses
      PeppolDestination.new(
        participantIdentifier, format['peppol-docid'], format['peppol-procid']
      ).access_points
      @order.order_response
      Haltr::Sender.send_order_response(@order, User.current)
    rescue PeppolDestinationException
      #TODO: send by email
      flash[:warning]="Participant has not published the capacity to handle OrderResponse documents in Peppol SMP: #{$!.message}"
    end
    Event.create!(order: @order, name: 'accept', user: User.current, project: @project)
    @order.update_column :state, 'accepted'
    redirect_to project_order_url(@order, project_id: @project)
  end

  private

  def find_order
    @order = Order.where(project_id: @project.id).find(params[:id])
  end

end
