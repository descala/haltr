module QuotesHelper

  def send_link_for_quote
    @invoice.client = Client.new if @invoice.client.nil?
    confirm = @invoice.has_been_sent? ? j(l(:sure_to_resend_quote, :num=>@invoice.number).html_safe) : nil
    if @invoice.valid? and ExportChannels.can_send?(:send_pdf_by_mail)
        # sending through invoices#send_invoice
        link_to_if_authorized l(:label_send),
          {:action=>'send_quote', :id=>@invoice},
          :class=>'icon-haltr-send', :title => @invoice.sending_info(:pdf_by_mail).html_safe,
          :data=>{:confirm => confirm}
    else
      # invoice has errors TODO: or a format without channel, like "paper"
      link_to l(:label_send), "#", :class=>'icon-haltr-send disabled',
        :title => @invoice.sending_info(:pdf_by_mail).html_safe
    end
  end

end
