class ReceivedInvoiceEvent < Event

  def to_s
    case name
    when 'email'
      "#{l(:by_mail_from, :email=>invoice.from)}"
    when 'uploaded'
      "#{l(:uploaded, :by=>user.name)}"
    else
      super
    end
  end

end
