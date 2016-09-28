class OrdersController < ApplicationController
  unloadable

  menu_item Haltr::MenuItem.new(:orders,:orders_level2)
  menu_item Haltr::MenuItem.new(:orders,:received), :only => [:received, :show_received]
  menu_item Haltr::MenuItem.new(:orders,:inexistent), :only => [:import]

  before_filter :find_project_by_project_id
  before_filter :authorize

  helper :sort
  helper :haltr
  include SortHelper

  accept_api_auth :import

  def index
    sort_init 'num_pedido'
    sort_update %w(num_pedido fecha_pedido lugar_entrega fecha_entrega fecha_documento)

    orders = nil
    if params[:received] == '1'
      orders = ReceivedOrder.where(project_id: @project.id)
    else
      orders = IssuedOrder.where(project_id: @project.id)
    end

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

    @order_count = orders.count
    @order_pages = Paginator.new self, @order_count,
      per_page_option,
      params[:page]
    @orders = orders.find :all,
      order: sort_clause,
      limit: @order_pages.items_per_page,
      offset: @order_pages.current.offset
  end

  def received
    params[:received] = '1'
    index
    render action: :index
  end

  def show
    @order = Order.where(project_id: @project.id).find(params[:id])
    if params[:download]
      send_data @order.original,
        :type => 'text/plain',
        :disposition => "attachment; filename=#{@order.filename}"
      return
    elsif @order.xml?
      doc  = Nokogiri::XML(@order.original)
      if doc.child and doc.child.name == "StandardBusinessDocument"
        doc = Haltr::Utils.extract_from_sbdh(doc)
      end
      xslt = Nokogiri.XSLT(File.open("#{File.dirname(__FILE__)}/../../lib/haltr/xslt/OIOUBL_Order.xsl",'rb'))
      @order_xslt_html = xslt.transform(doc)
    end
    render :show
  end

  def show_received
    show
  end

  def destroy
    order = Order.where(project_id: @project.id).find(params[:id])
    order.events.destroy_all
    order.destroy
    event = EventDestroy.new(:name    => "deleted_#{order.type.underscore}",
                             :notes   => order.num_pedido,
                             :project => order.project)
    event.save!
    if order and order.is_a? ReceivedOrder
      redirect_to action: :received
    else
      redirect_to action: :index
    end
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
          if @order and @order.is_a? IssuedOrder
            redirect_to project_order_path(@order, project_id: @project)
          elsif @order
            redirect_to project_received_order_path(@order, project_id: @project)
          end
        }
        format.api {
          render action: :show, status: :created, location: project_order_path(@order, project_id: @project)
        }
      end
    end
  rescue StandardError => e
    respond_to do |format|
      format.html {
        flash[:error] = e.message
      }
      format.api {
        render text: e.message, status: :unprocessable_entity
      }
    end
  end

  def add_comment
    @order = Order.where(project_id: @project.id).find(params[:id])
    @comment = Comment.new
    @comment.safe_attributes = params[:comment]
    @comment.author = User.current
    if @order.comments << @comment
      flash[:notice] = l(:label_comment_added)
    end

    if @order.is_a? ReceivedOrder
      redirect_to project_received_order_path(@order, project_id: @order.project)
    else
      redirect_to project_order_path(@order, project_id: @order.project)
    end
  end

end
