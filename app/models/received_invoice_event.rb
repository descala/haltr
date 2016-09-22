class ReceivedInvoiceEvent < Event

  def to_s
    case name
    when "peppol"
      l(:by_peppol)
    when "uploaded"
      super
    when "from_issued"
      l(:from_issued)
    else
      if invoice and invoice.from
        l(:by_mail_from, :email=>invoice.from)
      else
        l(:by_mail_from, :email=>'?')
      end
    end
  end

end
