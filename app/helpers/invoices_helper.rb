module InvoicesHelper

  DEFAULT_TAX_PERCENT_VALUES = { :format => "%t %n%p", :negative_format => "%t -%n%p", :separator => ".", :delimiter => ",",
                                 :precision => 2, :significant => false, :strip_insignificant_zeros => false, :tax_name => "VAT" }

  def change_state_link(invoice)
    if invoice.state?(:closed)
      link_to(I18n.t(:mark_not_sent), {:action => :mark_not_sent, :id => invoice},:class=>'icon-haltr-mark-not-sent')
    elsif invoice.sent? and invoice.is_paid?
      link_to(I18n.t(:mark_closed), {:action => :mark_closed, :id => invoice},:class=>'icon-haltr-mark-closed')
    elsif invoice.sent?
      link_to(I18n.t(:mark_not_sent), {:action => :mark_not_sent, :id => invoice},:class=>'icon-haltr-mark-not-sent')
    else
      link_to(I18n.t(:mark_sent), {:action => :mark_sent, :id => invoice},:class=>'icon-haltr-mark-sent')
    end
  end

  def accept_link(invoice)
    if invoice.state?(:received)
      link_to(I18n.t(:mark_accepted), {:action => :mark_accepted, :id => invoice})
    end
  end

  def clients_for_select
    clients = Client.find(:all, :order => 'name', :conditions => ["project_id = ?", @project])
    # check if client.valid?: if you request to link profile, and then unlink it, client is invalid
    clients.collect {|c| [c.name, c.id] if c.valid? }.compact
  end

  def add_invoice_line_link(invoice_form,received=false)
    link_to_function l(:button_add_invoice_line), :class=>"icon icon-add" do |page|
      invoice_form.fields_for(:invoice_lines, InvoiceLine.new, :child_index => 'NEW_RECORD') do |line_form|
        if received
          html = render(:partial => 'received_invoices/invoice_line', :locals => { :f => line_form })
        else
          html = render(:partial => 'invoices/invoice_line', :locals => { :f => line_form })
        end
        page << "$('invoice_lines').insert({ bottom: '#{escape_javascript(html)}'.replace(/NEW_RECORD/g, new Date().getTime()) });"
        @invoice.taxes_hash.each_key do |tax_name|
          #TODO: global_tax_check_changed does more things than necessary here
          page << "global_tax_check_changed('#{tax_name}');"
          page << "copy_last_line_tax('#{tax_name}');"
        end
      end
    end
  end

  def precision(num,precision=2)
    num=0 if num.nil?
    number_with_precision(num,:precision=>precision,:significant => true)
  end

  def download_link_for(e)
    if (e.name == "success_sending"||e.name == "validating_format") and !e.md5.blank?
      if e.invoice.type == "ReceivedInvoice"
        "( #{link_to l(:button_download), :controller=>'invoices', :action=>'legal', :id=>e.invoice, :md5=>e.md5} )"
      else
        "( #{link_to l(:download_legal), :controller=>'invoices', :action=>'legal', :id=>e.invoice, :md5=>e.md5} )"
      end
    elsif e.name =~ /_notification$/ and !e.md5.blank?
      "( #{link_to l(:download_notification), :controller=>'invoices', :action=>'legal', :id=>e.invoice, :md5=>e.md5} )"
    elsif ( e.name == "accept" || e.name == "refuse" || e.name == "paid" ) && !e.info.blank?
      "( #{link_to_function(l(:view_mail), "$('event_#{e.id}').show();")} )"
    elsif e.name == "new" and e.invoice and e.invoice.client and e.invoice.visible_by_client?
      " (#{link_to(l(:public_link), :controller=>'invoices', :action=>'view', :id=>e.invoice.client.hashid, :invoice_id=>e.invoice.id)})"
    else
      ""
    end
  end

  def frequencies_for_select
    [1,2,3,6,12].collect do |f|
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
    @project.issued_invoices.count(:conditions => ["state='new' and number is not null and date <= ?", Date.today])
  end

  def transport_text(invoice)
    if invoice.transport == "email"
      l(:by_mail_from, :email => invoice.from)
    #eslif invoice.transport == "upload" ...
    end
  end

  def tax_name(tax, options = {})
    return nil if tax.nil?

    return "#{tax.name} #{l(:tax_E)}" if tax.exempt?

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
      if User.current.logged?
        link_to(invoice.number, {:action=>'show', :id=>invoice})
      else
        link_to(invoice.number, {:action=>'view', :id=>invoice.client.hashid, :invoice_id=>invoice.id})
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

  def l_export_channel(export_channel)
    if channel = ExportChannels.available[export_channel]
      channel["locales"][I18n.locale.to_s]
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
    if category == 'E'
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
    if @invoice.taxes.collect {|t| t if t.name==name and t.exempt?}.compact.any?
      return ""
    else
      return "hidden"
    end
  end

end
