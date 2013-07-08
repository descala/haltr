class InvoiceTemplatesController < InvoicesController 

  unloadable
  menu_item Haltr::MenuItem.new(:invoices,:templates)

  # skip parent controller filters, add later
  # otherwise they get executed before ours
  skip_before_filter :authorize, :check_for_company

  before_filter :find_project_by_project_id, :only => [:update_taxes]
  before_filter :find_issued_invoice, :only => [:new_from_invoice]
  before_filter :authorize, :check_for_company

  def index
    sort_init 'date', 'asc'
    sort_update %w(date number clients.name)

    templates = @project.invoice_templates.scoped

    unless params[:name].blank?
      name = "%#{params[:name].strip.downcase}%"
      templates = templates.scoped :conditions => ["LOWER(name) LIKE ? OR LOWER(address) LIKE ? OR LOWER(address2) LIKE ?", name, name, name]
    end

    @invoice_count = templates.count
    @invoice_pages = Paginator.new self, @invoice_count,
		per_page_option,
		params['page']
    @invoices =  templates.find :all,
       :order => sort_clause,
       :include => [:client],
       :limit  =>  @invoice_pages.items_per_page,
       :offset =>  @invoice_pages.current.offset
  end

  def new_from_invoice
    @invoice = InvoiceTemplate.new(@issued_invoice.attributes)
    @invoice.number=nil
    @issued_invoice.invoice_lines.each do |line|
      tl = InvoiceLine.new(line.attributes)
      line.taxes.each do |tax|
        tl.taxes << Tax.new(tax.attributes)
      end
      @invoice.invoice_lines << tl
    end
    render :template => "invoices/new"
  end

  def show
    @invoices_generated = @invoice.issued_invoices.sort
  end

  # creates new draft invoices from template
  def new_invoices_from_template
    @number = IssuedInvoice.next_number(@project)
    days = params[:date] || 10
    @date = Date.today + days.to_i.day
    templates = InvoiceTemplate.find :all, :include => [:client], :conditions => ["clients.project_id = ? and date <= ?", @project.id, @date], :order => "date ASC"
    @drafts = DraftInvoice.find :all, :include => [:client], :conditions => ["clients.project_id = ?", @project.id], :order => "date ASC"
    templates.each do |t|
      begin
        @drafts << t.invoices_until(@date)
      rescue ActiveRecord::RecordInvalid => e
        flash.now[:warning] = l(:warning_can_not_generate_invoice,t.to_s)
        flash.now[:error] = e.message
      end
    end
    @drafts.flatten!
  end

  # creates invoices form draft invoices
  def create_invoices
    @number = IssuedInvoice.next_number(@project)
    drafts_to_process=[]
    @invoices = []
    if params[:draft_ids]
      params[:draft_ids].each do |draft_id|
        drafts_to_process << DraftInvoice.find(draft_id)
      end
    end
    drafts_to_process.each do |draft|
      issued = IssuedInvoice.new(draft.attributes)
      issued.number = params["draft_#{draft.id}"]
      draft.invoice_lines.each do |draft_line|
        l = InvoiceLine.new draft_line.attributes
        draft_line.taxes.each do |tax|
          l.taxes << Tax.new(:name=>tax.name,:percent=>tax.percent)
        end
        issued.invoice_lines << l
      end
      if issued.valid?
        draft.destroy
        issued.id=draft.id
        issued.save
        @invoices << issued
      else
        flash.now[:error] = issued.errors.full_messages.join ","
      end
    end
    @drafts = DraftInvoice.find :all, :include => [:client], :conditions => ["clients.project_id = ?", @project.id], :order => "date ASC"
    render :action => 'new_invoices_from_template'
  end

  # this is a helper to mass-update the taxes of templates
  def update_taxes
    num_changed = 0
    from_name = params[:from_name]
    from_percent = params[:from_percent].to_i
    @used_taxes = []
    @project.invoice_templates.each do |template|
      template_changed = false
      template.invoice_lines.each do |line|
        line.taxes.each do |tax|
          if tax.name == from_name and tax.percent == from_percent
            tax.name = params[:to_name]
            tax.percent = params[:to_percent].to_i
            if tax.save
              num_changed = num_changed + 1
              template_changed = true
            end
          end
          @used_taxes << tax unless @used_taxes.include? tax
        end
      end
      template.save if template_changed
    end
    flash.now[:notice] = "Updated #{num_changed} template lines" if from_name and from_percent
  end

  def invoice_class
    InvoiceTemplate
  end

  def find_issued_invoice
    @issued_invoice = IssuedInvoice.find params[:id]
    @client = @issued_invoice.client
    @project = @issued_invoice.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
