module InvoicesHelper

  def change_state_link(invoice)
    if invoice.state?(:closed)
      link_to(I18n.t(:mark_not_sent), {:action => :mark_not_sent, :id => invoice},:class=>'icon-haltr-mark-not-sent')
    elsif invoice.sent? and invoice.paid?
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
    link_to_function l(:button_add_invoice_line) do |page|
      invoice_form.fields_for(:invoice_lines, InvoiceLine.new, :child_index => 'NEW_RECORD') do |line_form|
        if received
          html = render(:partial => 'received_invoices/invoice_line', :locals => { :f => line_form })
        else
          html = render(:partial => 'invoices/invoice_line', :locals => { :f => line_form })
        end
        page << "$('invoice_lines').insert({ bottom: '#{escape_javascript(html)}'.replace(/NEW_RECORD/g, new Date().getTime()) });"
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
    elsif ( e.name == "accept" || e.name == "refuse" ) && !e.info.blank?
      "( #{link_to_function(l(:view_mail), "$('event_#{e.id}').show();")} )"
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
    IssuedInvoice.find_not_sent(@project).size
  end

  def transport_text(invoice)
    if invoice.transport == "email"
      l(:by_mail_from, :email => invoice.from)
    #eslif invoice.transport == "upload" ...
    end
  end

end
