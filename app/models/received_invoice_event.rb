class ReceivedInvoiceEvent < Event

  after_create :call_after_create_hook

  def to_s
    if name == 'email' and invoice and invoice.from
      l(:by_mail_from, email: invoice.from)
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
