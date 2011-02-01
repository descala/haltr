class InvoiceDocument < Invoice

  # https://rails.lighthouseapp.com/projects/8994/tickets/2389-sti-changes-behavior-depending-on-environment
  require_association "received_invoice"
  require_association "issued_invoice"

  unloadable

end

