class ReceivedInvoiceEvent < Event

  def to_s
    case name
    when "peppol"
      "#{l(:by_peppol)}"
    when "uploaded"
      super
    else
      if invoice and invoice.from
        "#{l(:by_mail_from, :email=>invoice.from)}"
      else
        "#{l(:by_mail_from, :email=>'?')}"
      end
    end
  end

end
