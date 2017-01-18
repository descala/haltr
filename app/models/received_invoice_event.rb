class ReceivedInvoiceEvent < Event

  after_create :call_after_create_hook

  def to_s
    case name
    when 'email'
      "#{l(:by_mail_from, :email=>invoice.from)}"
    when "peppol"
      l(:by_peppol)
    when "uploaded"
      super
    when "from_issued"
      l(:from_issued)
    else
      l(:received_by, transport:
        I18n.t("from_#{name}", default: I18n.t(name, default: name.to_s.upcase))
       )
    end
  end

  def call_after_create_hook
    Redmine::Hook.call_hook(:model_received_invoice_event_after_create, :event=>self)
  end

end
