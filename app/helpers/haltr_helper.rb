# Methods added to this helper will be available to all templates in the application.
module HaltrHelper

  include Cocoon::ViewHelpers

  # Renders flash messages
  def render_flash_messages
    s = ''
    flash.each do |k,v|
      s << content_tag('div', v, :class => "flash #{k}")
    end
    s.html_safe
  end

  def money(import)
    currency = Money::Currency.new(import.currency)
    currency_symbol = currency.symbol || ""
    if currency.subunit_to_unit == 1
      number_to_currency(import, :unit => currency_symbol, :precision => 0)
    else
      number_to_currency(import, :unit => currency_symbol)
    end
  end

  def line_price(line, price='price', invoice=nil)
    decimals = line.send(price).to_s.split(".").last
    precision = decimals.size
    precision = 0 if decimals =~ /^0+$/
    precision = 2 if precision == 1
    invoice ||= line.invoice
    currency = Money::Currency.new(invoice.currency)
    currency_symbol = currency.symbol || ""
    if currency.subunit_to_unit == 1 and precision == 2
      precision = 0
    end
    number_to_currency(line.send(price), :unit => currency_symbol, :precision => precision)
  end

  def quantity(q)
    if q.floor == q
      q.to_i
    else
      number_with_delimiter q, :delimiter => ".", :separator => ","
    end
  end

  def notify_pending_requests(project)
    if project.company.companies_with_link_requests.any?
      "<span style='color: #dd6600;'>(#{l(:pending_requests,:i=>project.company.companies_with_link_requests.size)})</span>"
    end
  end

  def self.currency_options_for_select
    opts = []
    Money::Currency.table.each do |id,attributes|
      if attributes[:priority] && attributes[:priority] < 105
        opts << ["#{id.to_s.upcase} - #{attributes[:name]}",id.to_s.upcase]
      end
    end
    opts.compact.sort {|x,y|
      if x[1] == "EUR"
        -1
      elsif y[1] == "EUR"
        1
      elsif x[1] == "USD"
        -1
      elsif y[1] == "USD"
        1
      else
        x[0] <=> y[0]
      end
    }
  end

  def currency_options_for_select
    HaltrHelper.currency_options_for_select
  end

  def help(topic)
    content_tag("span",:class=>'help') do
      image_tag('help.png', :title => l(topic))
    end
  end

  def hide_to_user(action)
    return (Setting.plugin_haltr['hide_unauthorized'] and !User.current.allowed_to?(action,@project))
  end

  def selclass(controller,action)
    if params[:controller].to_s == controller.to_s and
      params[:action].to_s == action.to_s
      "sel"
    end
  end

  # overwrite redmine helper to allow url passed as string
  # (to allow use with new _path helpers)
  def link_to_if_authorized(name, options = {}, html_options = {}, *parameters_for_method_reference)
    parsed_options = options
    if options.is_a?(String)
      parsed_options = Rails.application.routes.recognize_path(options, html_options)
    end
    link_to(name, options, html_options, *parameters_for_method_reference) if authorize_for(parsed_options[:controller] || params[:controller], parsed_options[:action])
  rescue ActionController::RoutingError
  end

  def n19taxcode(taxcode)
    if taxcode and taxcode.size > 9
      taxcode.last(9)
    else
      taxcode
    end
  end

  def iban_for_mandate
    if @client.iban.blank?
      #iban = "#{@client.country_alpha2}______________________"
      iban = "________________________"
    else
      iban = @client.iban
    end
    iban.gsub(/(.)/,'\1 ').gsub(/(. . . .)/,'\1 ').gsub(/ /,'&nbsp;')
  end

  def link_to_invoice_with_label(invoice)
    case invoice.type
    when 'InvoiceTemplate'
      controller = 'invoice_templates'
      label = "#{l('label_invoice_template')} ##{invoice.id}"
    when 'ReceivedInvoice'
      controller = 'received'
      label = l('label_invoice')
    else
      controller = 'invoices'
      label = l('label_invoice')
    end
    link_to("#{label} #{invoice.number}",
            { :controller=>controller,
              :action=>'show',
              :id=>invoice,:anchor=>'haltr_events' },
            :title=>invoice.client ? invoice.client.name : '')
  end

  def label_for_audit(name)
    parsed_name = name.gsub(/_id$/,'').gsub(/_in_cents$/,'')
    l("field_#{parsed_name}", :default=>parsed_name.gsub(/_/,' ').capitalize)
  end

  def value_for_audit(name,value)
    if name =~ /_id$/
      related = name.gsub(/_id$/,'').camelize.constantize.find(value.to_i) rescue nil
      if related and related.respond_to? :name
        related.name
        #TODO elsif ...
      else
        value
      end
    elsif name == "payment_method"
      case value
      when Invoice::PAYMENT_CASH
        l(:cash)
      when Invoice::PAYMENT_DEBIT
        l(:debit)
      when Invoice::PAYMENT_TRANSFER
        l(:transfer)
      when Invoice::PAYMENT_SPECIAL
        l(:other)
      else
        value
      end
    elsif name == "terms"
      l(value, :default=>value)
    elsif name == "unit"
      l(InvoiceLine::UNIT_CODES[value][:name], :default=>value) rescue value
    elsif name == "country"
      ISO::Countries.get_country(value)
    elsif name == "language"
      l(:general_lang_name,:locale=>value, :default=>value)
    elsif name == "invoice_format"
      ExportChannels.l(value)
    elsif name == "category"
      l("tax_#{value}", :default=>value)
    else
      value
    end
  end

  def colspan_for(invoice)
    colspan  = 1
    colspan += 1 if invoice.has_line_discounts?
    colspan += 1 if invoice.has_line_charges?
    return "colspan=#{colspan}" if colspan > 0
  end

end
