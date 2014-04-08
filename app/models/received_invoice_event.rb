class ReceivedInvoiceEvent < Event

  def to_s
    "#{l(:by_mail_from, :email=>invoice.from)}"
  end

end
