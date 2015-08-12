module InvoicesHelper

  DEFAULT_TAX_PERCENT_VALUES = { :format => "%t %n%p", :negative_format => "%t -%n%p", :separator => ".", :delimiter => ",",
                                 :precision => 2, :significant => false, :strip_insignificant_zeros => false, :tax_name => "VAT" }
  def clients_for_select
    clients = Client.find(:all, :order => 'name', :conditions => ["project_id = ?", @project])
    # check if client.valid?: if you request to link profile, and then unlink it, client is invalid
    clients.collect {|c| [c.name, c.id, {'data-invoice_format'=>ExportChannels.l(c.invoice_format)}] unless c.name.blank?}.compact
  end

  def haltr_precision(num,precision=2)
    num=0 if num.nil?
    # :significant - If true, precision will be the # of significant_digits. If false, the # of fractional digits
    number_with_precision(num,:precision=>precision,:significant => false)
  end

  def send_link_for_invoice
    confirm = @invoice.sent? ? j(l(:sure_to_resend_invoice, :num=>@invoice.number).html_safe) : nil
    if @invoice.valid? and @invoice.can_queue? and
        ExportChannels.can_send?(@invoice.client.invoice_format)
      unless @js.blank?
        # channel uses javascript to send invoice
        if User.current.allowed_to?(:general_use, @project)
          link_to(l(:label_send), "#", :class=>'icon-haltr-send',
            :title   => @invoice.sending_info.html_safe,
            :onclick => ((confirm ? "confirm('#{confirm}') && " : "") +
                        @js.gsub(':id',@invoice.id.to_s)).html_safe)
        end
      else
        # sending through invoices#send_invoice
        link_to_if_authorized l(:label_send),
          {:action=>'send_invoice', :id=>@invoice},
          :class=>'icon-haltr-send', :title => @invoice.sending_info.html_safe,
          :confirm => confirm
      end
    elsif @invoice.can_queue?
      # invoice has export errors (related to the format or channel)
      # or a format without channel, like "paper"
      link_to l(:label_send), "#", :class=>'icon-haltr-send disabled',
        :title => @invoice.sending_info.html_safe
    else
      link_to l(:label_send), "#", :class=>'icon-haltr-send disabled',
        :title => ("#{@invoice.sending_info}<br/>" +
        "#{I18n.t(:state_not_allowed_for_sending, state: I18n.t("state_#{@invoice.state}"))}").html_safe
    end
  end

  def confirm_for(invoice_ids)
    to_confirm = Invoice.find(invoice_ids).select { |invoice|
      invoice.sent?
    }.collect {|invoice| invoice.number }
    if to_confirm.empty?
      return nil
    elsif to_confirm.size == 1
      return l(:sure_to_resend_invoice, :num => to_confirm.first)
    else
      return l(:sure_to_resend_invoices, :nums => to_confirm.join(", "))
    end
  end

  def frequencies_for_select
    [1,2,3,6,12,24,36].collect do |f|
      [I18n.t("mf#{f}"), f]
    end
  end

  def num_new_invoices
    pre_drafts = InvoiceTemplate.count(:include=>[:client],:conditions => ["clients.project_id = ? AND date <= ?", @project, Date.today + 10.day])
    drafts = DraftInvoice.count(:include=>[:client],:conditions => ["clients.project_id = ?", @project])
    pre_drafts + drafts
  end

  def num_not_sent
    @project.issued_invoices.count(:conditions => "state='new' and number is not null")
  end

  def num_can_be_sent
    @project.issued_invoices.includes(:client).count(
      :conditions => [
        "state='new' and number is not null and date <= ? and clients.invoice_format in (?)",
        Date.today,
        ExportChannels.can_send.keys
      ]
    )
  end

  def tax_name(tax, options = {})
    return nil if tax.nil?

    return "#{tax.name} #{l("tax_#{tax.category}")}" if tax.exempt?

    options.symbolize_keys!
    default_format = I18n.translate(:'number.format',
                                    :locale => options[:locale],
                                    :default => {})
    tax_format   = I18n.translate(:'number.tax.format',
                                  :locale => options[:locale],
                                  :default => {})
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
      value = number_with_precision(number, options.merge(:raise => true))
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
        link_to(invoice.number, {:action=>'show', :id=>invoice})
      elsif invoice.visible_by_client?
        link_to(invoice.number, {:action=>'view', :client_hashid=>invoice.client.hashid, :invoice_id=>invoice.id}, :class=>'public')
      else
        nil
      end
    end
  end

  def client_name_with_link(client)
    if authorize_for('clients', 'edit')
      link_to h(client.name), {:controller=>'clients',:action=>'edit',:id=>client}
    else
      h(client.name)
    end
  end

  def tax_categories_array(invoice,tax_name)
    # tax_name = 'VAT'
    taxes = invoice.taxes_hash[tax_name].sort
    show_category = false
    if taxes.size != taxes.collect {|t| t.percent}.uniq.size
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
      return "display: none"
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
    if i.is_a?(IssuedInvoice) or i.is_a?(Quote)
      if i.debit?
        # IssuedInvoice + debit, show clients iban
        if i.client.use_iban?
          iban = i.client.iban || ""
          bic  = i.client.bic || ""
          s="#{l(:debit_str)}<br />"
          s+="IBAN #{iban[0..3]} #{iban[4..7]} #{iban[8..11]} **** **** #{iban[20..23]}<br />"
          s+="BIC #{bic}<br />" unless bic.blank?
          s
        else
          ba = i.client.bank_account || ""
          "#{l(:debit_str)}<br />#{ba[0..3]} #{ba[4..7]} ** ******#{ba[16..19]}"
        end
      elsif i.transfer? and i.bank_info
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
      elsif i.transfer?
        # ReceivedInvoice + transfer, show clients iban
        if i.client.use_iban?
          iban = i.client.iban || ""
          bic  = i.client.bic || ""
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

  def select_to_edit(field)
    if @external_company and @external_company.send("dir3_#{field.to_s.pluralize}").any?
      content_tag(:span, image_tag('edit.png'), data: {field: field}, class: 'select_to_edit required')
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
end
