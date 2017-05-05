module InvoicesHelper

  DEFAULT_TAX_PERCENT_VALUES = { format: "%t %n%p", negative_format: "%t -%n%p", separator: ".", delimiter: ",",
                                 precision: 2, significant: false, strip_insignificant_zeros: false, tax_name: "VAT" }
  def clients_for_select
    clients = Client.where(project: @project).order(:name)
    # check if client.valid?: if you request to link profile, and then unlink it, client is invalid
    clients.collect {|c| [c.name, c.id, {'data-invoice_format'=>ExportChannels.l(c.invoice_format)}] unless c.name.blank?}.compact
  end

  def haltr_precision(num, precision=2, relevant=nil)
    num = 0 if num.nil?
    if relevant.present?
      # relevant first cuts the number, then precision will add zeros
      num = number_with_precision(num, precision: relevant)
    end
    num = number_with_precision(num, precision: precision)
    num
  end

  def edi_number(num)
    # 123456.78
    number_with_precision(num, precision: 2, locale: :en)
  end

  def edi_date(date)
    date = Date.today if date.nil?
    date.strftime("%Y%m%d")
  end

  def send_link_for_invoice
    confirm = @invoice.has_been_sent? ? j(l(:sure_to_resend_invoice, num: @invoice.number).html_safe) : nil
    if @invoice.valid? and @invoice.may_queue? and
        ExportChannels.can_send?(@invoice.client.invoice_format)
      if @invoice.client.sign_with_local_certificate?
        # channel uses javascript to send invoice
        if User.current.allowed_to?(:general_use, @project)
          link_to(l(:label_send), "#", class: 'icon-fa icon-fa-send',
            title: @invoice.sending_info.html_safe,
            onclick: ((confirm ? "confirm('#{confirm}') && " : "") +
                         @invoice.local_cert_js).html_safe)
        end
      else
        # sending through invoices#send_invoice
        link_to_if_authorized l(:label_send),
          {action: 'send_invoice', id: @invoice},
          class: 'icon-fa icon-fa-send', title: @invoice.sending_info.html_safe,
          data: {confirm: confirm}
      end
    elsif @invoice.may_queue?
      # invoice has export errors (related to the format or channel)
      # or a format without channel, like "paper"
      link_to l(:label_send), "#", class: 'icon-fa icon-fa-send disabled',
        title: @invoice.sending_info.html_safe
    else
      link_to l(:label_send), "#", class: 'icon-fa icon-fa-send disabled',
        title: ("#{@invoice.sending_info}<br/>" +
        "#{I18n.t(:state_not_allowed_for_sending, state: I18n.t("state_#{@invoice.state}"))}").html_safe
    end
  end

  def confirm_for(invoice_ids)
    to_confirm = Invoice.find(invoice_ids).select { |invoice|
      invoice.has_been_sent?
    }.collect {|invoice| invoice.number }
    if to_confirm.empty?
      return nil
    elsif to_confirm.size == 1
      return l(:sure_to_resend_invoice, num: to_confirm.first)
    else
      return l(:sure_to_resend_invoices, nums: to_confirm.join(", "))
    end
  end

  def frequencies_for_select
    [1,2,3,6,12,24,36,60].collect do |f|
      [I18n.t("mf#{f}"), f]
    end
  end

  def num_new_invoices
    pre_drafts = InvoiceTemplate.includes(:client).references(:client).where("clients.project_id = ? AND date <= ?", @project, Date.today + 10.day).count
    drafts = DraftInvoice.includes(:client).references(:client).where("clients.project_id = ?", @project.id).count
    pre_drafts + drafts
  end

  def num_not_sent
    IssuedInvoice.find_not_sent(@project).count
  end

  def num_can_be_sent
    IssuedInvoice.find_can_be_sent(@project).count
  end

  def tax_name(tax, options = {})
    return nil if tax.nil?

    return "#{tax.name} #{l("tax_#{tax.category}")}" if tax.exempt?

    options.symbolize_keys!
    default_format = I18n.translate(:'number.format',
                                    locale: options[:locale],
                                    default: {})
    tax_format   = I18n.translate(:'number.tax.format',
                                  locale: options[:locale],
                                  default: {})
    default_format  = DEFAULT_TAX_PERCENT_VALUES.merge(default_format).merge!(tax_format)
    default_format[:negative_format] = "-" + options[:format] if options[:format]
    options = default_format.merge!(options)
    format  = options.delete(:format)

    number = tax.percent.to_f
    if number < 0
      format = options.delete(:negative_format)
      number = tax.percent.respond_to?("abs") ? tax.percent.abs : tax.percent.sub(/^-/, '')
    end

    begin
      value = number_with_precision(number, options.merge(raise: true))
      format.gsub(/%n/, value).gsub(/%p/, '%').gsub(/%t/,tax.name)
    rescue
      number
    end
  end

  def link_to_invoice(invoice, current=nil)
    if invoice == current
      invoice.number
    else
      if User.current.admin? or (User.current.logged? and User.current.projects.include?(invoice.project))
        link_to(invoice.number, {action: 'show', id: invoice})
      elsif invoice.visible_by_client?
        link_to(invoice.number, {action: 'view', client_hashid: invoice.client.hashid, invoice_id: invoice.id}, class: 'public')
      else
        nil
      end
    end
  end

  def client_name_with_link(client)
    if authorize_for('clients', 'show')
      link_to h(client.name), {controller: 'clients', action: 'show', id: client}, class: 'underline'
    else
      h(client.name)
    end
  end

  def tax_categories_array(invoice,tax_name)
    # tax_name = 'VAT'
    taxes = invoice.taxes_hash[tax_name].sort
    show_category = false
    if taxes.size != taxes.collect {|t| t.percent}.uniq.size or tax_name == 'RE'
      show_category = true
    end
    taxes.collect do |tax|
      tax_label(tax.code,show_category)
    end.insert(0,'')
  end

  def tax_label(tax_code,show_category=false)
    # tax_code = '21.0_S'
    percent, category = tax_code.split('_')
    if category == 'E' or category == 'NS'
      [l("tax_#{category}"), tax_code]
    else
      if show_category
        ["#{percent}% #{l("tax_#{category}")}", tax_code]
      else
        ["#{percent}%", tax_code]
      end
    end
  end

  def hide_if_not_exempt_tax(name)
    if (@invoice.taxes.collect {|t| t if t.name==name and t.exempt?}.compact.any?) or
       (@invoice.new_record? and @invoice.global_code_for(name).match(/_E$/))
      return ""
    else
      return "no-display"
    end
  end

  def edit_invoice_path_multiclass(invoice)
    if invoice.is_a? InvoiceTemplate
      edit_invoice_template_path invoice
    else
      edit_invoice_path invoice
    end
  end

  def invoice_path_multiclass(invoice)
    if invoice.is_a? InvoiceTemplate
      invoice_template_path invoice
    else
      invoice_path invoice
    end
  end

  def payment_method_info
    i = @invoice
    if i.is_a?(IssuedInvoice) or i.is_a?(Quote) or i.is_a?(InvoiceTemplate)
      if i.debit?
        # IssuedInvoice + debit, show clients iban
        if i.client.use_iban?
          iban = i.client_iban || ""
          bic  = i.client_bic || ""
          s="#{l(:debit_str)}<br />"
          s+="IBAN #{iban[0..3]} #{iban[4..7]} #{iban[8..11]} **** **** #{iban[20..23]}<br />"
          s+="BIC #{bic}<br />" unless bic.blank?
          s
        else
          ba = i.client.bank_account || ""
          "#{l(:debit_str)}<br />#{ba[0..3]} #{ba[4..7]} ** ******#{ba[16..19]}"
        end
      elsif i.transfer?
        if i.bank_info
          # IssuedInvoice + transfer, show our iban
          if i.bank_info.use_iban?
            iban = i.bank_info.iban || ""
            bic  = i.bank_info.bic || ""
            s="#{l(:transfer_str)}<br />"
            s+="IBAN #{iban.scan(/.{1,4}/).join(' ')}<br />"
            s+="BIC #{bic}<br />" unless bic.blank?
            s
          else
            ba = i.bank_info.bank_account ||= "" rescue ""
            "#{l(:transfer_str)}<br />" +
              "#{ba[0..3]} #{ba[4..7]} #{ba[8..9]} #{ba[10..19]}"
          end
        else
          l(:transfer)
        end
      elsif i.credit?
        l(:fa_payment_method_19)
      elsif i.special?
        i.payment_method_text
      elsif i.cash?
        l(:cash_str)
      end
    elsif i.is_a? ReceivedInvoice
      if i.debit? and i.bank_info
        # ReceivedInvoice + debit, show our iban
        if i.bank_info.use_iban?
          iban = i.bank_info.iban || ""
          bic  = i.bank_info.bic || ""
          s="#{l(:debit_str)}<br />"
          s+="IBAN #{iban.scan(/.{1,4}/).join(' ')}<br />"
          s+="BIC #{bic}<br />" unless bic.blank?
          s
        else
          ba = i.bank_info.bank_account ||= "" rescue ""
          "#{l(:debit_str)}<br />" +
            "#{ba[0..3]} #{ba[4..7]} #{ba[8..9]} #{ba[10..19]}"
        end
      elsif i.debit?
        # ReceivedInvoice without bank_info, show only 'debit'
          "#{l(:debit_str)}<br />"
      elsif i.transfer?
        # ReceivedInvoice + transfer, show clients iban
        if i.client.use_iban?
          iban = i.client_iban || ""
          bic  = i.client_bic || ""
          s="#{l(:transfer_str)}<br />"
          s+="IBAN #{iban.scan(/.{1,4}/).join(' ')}<br />"
          s+="BIC #{bic}<br />" unless bic.blank?
          s
        else
          ba = i.client.bank_account || ""
          "#{l(:transfer_str)}<br />#{ba[0..3]} #{ba[4..7]} #{ba[8..9]} #{ba[10..19]}"
        end
      elsif i.special?
        i.payment_method_text
      else
        l(:cash_str)
      end
    else
      ""
    end
  end

  def dir3_for_select(entities)
    entities.collect {|entity|
      if entity.code == entity.name
        [entity.name, entity.code]
      else
        ["#{entity.name} - #{entity.code}", entity.code]
      end
    }
  end

  def required_field_span(field)
    if (@external_company and @external_company.required_fields.include?(field)) or
        (field == 'dir3' and @client and @client.invoice_format =~ /face/)
      content_tag(:span, ' *', class: 'required')
    end
  end

  # has_custom_value is true when field has value not included in select
  def select_to_edit(field, has_custom_value)
    if @external_company and @external_company.send("dir3_#{field.to_s.pluralize}").any?
      if has_custom_value
        content_tag :span,
          l(:button_cancel),
          data: {field: field, text: l(:button_edit)},
          class: 'icon-fa fa-ban select_to_edit control-label'
      else
        content_tag :span,
          l(:button_edit),
          data: {field: field, text: l(:button_cancel)},
          class: 'icon-fa icon-fa-pencil select_to_edit control-label'
      end
    end
  end

  def facturae_attachment_format(attachment)
    valid_formats = %W(xml doc gif rtf pdf xls jpg bmp tiff)
    extension = attachment.filename.split('.').last.downcase
    if valid_formats.include?(extension)
      extension
    else
      'doc'
    end
  end

  def invoice_summary(invoice)
    lines = Array.new
    invoice.invoice_lines.each_with_index do |line,i|
      break if i > 2
      lines << truncate(line.description, length: 50)
    end
    desc = Array.new
    desc << money(invoice.total)
    desc << invoice.date unless invoice.is_a? InvoiceTemplate
    desc << lines.join(" | ")
    desc.join(" * ")
  end

  def invoice_public_view_with_host(h)
    invoice_public_view_url(h.merge(host: Setting.host_name, protocol: Setting.protocol))
  end

  def display_series_code_in_form?
    ((@invoice.company.country == 'es' or @invoice.series_code.present?) and
      User.current.allowed_to?(:view_invoice_extra_fields,@project))
  end

  def invoice_imgs_context_menu(url)
    unless @context_menu_included
      content_for :header_tags do
        javascript_include_tag('invoice_imgs_context_menu?v=2', plugin: 'haltr') +
          stylesheet_link_tag('context_menu?v=2')
      end
      if l(:direction) == 'rtl'
        content_for :header_tags do
          stylesheet_link_tag('context_menu_rtl?v=2')
        end
      end
      @context_menu_included = true
    end
    javascript_tag "contextMenuInit('#{ url_for(url) }')"
  end
  def invoice_img_tag_div(invoice_img, tag)
    reference = invoice_img.tags[tag]
    if reference.is_a? Array
      x = 0
      y = 0
      reference.each do |number|
        attributes = invoice_img.tokens[number.to_i]
        x = attributes[:x1].to_i if attributes[:x1].to_i > x
        y = attributes[:y0].to_i if attributes[:y0].to_i > y
      end
    else
      return if invoice_img.tokens[reference].nil?
      attributes = invoice_img.tokens[reference]
      x = attributes[:x1].to_i
      y = attributes[:y0].to_i
    end
    "<div class=\"rectangle-tag\" style=\"left:#{x+8}px; top:#{y}px;\">#{l("tag_#{tag}")}</div>".html_safe
  end
  def invoice_img_token_style(attributes)
    font_size = [attributes[:y1].to_i-attributes[:y0].to_i-1, 9].max
    font_size = 16 if font_size > 16
    "left:#{attributes[:x0].to_i-1}px; top:#{attributes[:y0].to_i-1}px; height:#{attributes[:y1].to_i-attributes[:y0].to_i+2}px; min-width:#{attributes[:x1].to_i-attributes[:x0].to_i+2}px; font-size:#{font_size}px; line-height: <%=font_size%>px;"
  end

  def index_url_helper
    if @invoice.is_a? IssuedInvoice
      project_invoices_path(@project)
    elsif @invoice.is_a? ReceivedInvoice
      project_received_index_path(@project)
    elsif @invoice.is_a? InvoiceTemplate
      project_invoice_templates_path(@project)
    elsif @invoice.is_a? Quote
      project_quotes_path(@project)
    else
      raise "unknown object type: #{@invoice.class}"
    end
  end

end
