class ReceivedInvoiceEvent < Event

  def to_s
    if invoice
      "#{l(:by_mail_from, :email=>invoice.from)}"
    else
      "#{l(:by_mail_from)}"
    end
  end

end
