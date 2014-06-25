module QuotesHelper

  def send_link_for_quote
    confirm = @invoice.sent? ? j(l(:sure_to_resend_quote, :num=>@invoice.number).html_safe) : nil
    if @invoice.can_be_exported?(:pdf_by_mail)
        # sending through invoices#send_invoice
        link_to_if_authorized l(:label_send),
          {:action=>'send_quote', :id=>@invoice},
          :class=>'icon-haltr-send', :title => @invoice.sending_info(:pdf_by_mail).html_safe,
          :confirm => confirm
    else
      # invoice has export errors (related to the format or channel)
      # or a format without channel, like "paper"
      link_to l(:label_send), "#", :class=>'icon-haltr-send disabled',
        :title => @invoice.sending_info(:pdf_by_mail).html_safe
    end
  end

end
