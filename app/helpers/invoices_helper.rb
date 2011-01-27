module InvoicesHelper

  def change_state_link(invoice)
    if invoice.state?(:closed)
      link_to("Mark as not sent", {:action => :mark_not_sent, :id => invoice})
    elsif invoice.sent? and invoice.paid?
      link_to("Mark as closed", {:action => :mark_closed, :id => invoice})
    elsif invoice.sent?
      link_to("Mark as not sent", {:action => :mark_not_sent, :id => invoice})
    else
      link_to("Mark as sent", {:action => :mark_sent, :id => invoice})
    end
  end

  def clients_for_select
    Client.find(:all, :order => 'name', :conditions => ["project_id = ?", @project]).collect {|c| [ c.name, c.id ] }
  end

  def add_invoice_line_link(invoice_form)
    link_to_function l(:button_add_invoice_line) do |page|
      invoice_form.fields_for(:invoice_lines, InvoiceLine.new, :child_index => 'NEW_RECORD') do |line_form|
        html = render(:partial => 'invoices/invoice_line', :locals => { :f => line_form })
        page << "$('invoice_lines').insert({ bottom: '#{escape_javascript(html)}'.replace(/NEW_RECORD/g, new Date().getTime()) });"
      end
    end
  end

  def precision(num,precision=2)
    num=0 if num.nil?
    number_with_precision(num,:precision=>precision,:significant => true)
  end

  def download_link_for(e)
    if e.name == "success_sending" and !e.md5.blank?
      "( #{link_to l(:download_legal), :controller=>'invoices', :action=>'get_legal', :id=>e.invoice, :md5=>e.md5} )"
    else
      ""
    end
  end

  def frequencies_for_select
    [1,3,6,12].collect do |f|
      [I18n.t("mf#{f}"), f]
    end
  end

end
