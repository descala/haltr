class InvoiceImg < ActiveRecord::Base
  unloadable

  belongs_to :invoice
  validate :has_associated_invoice

  serialize :data

  def has_associated_invoice
    errors.add(:invoice) unless self.invoice and self.invoice.is_a? InvoiceDocument
  end

  after_create do
    update_invoice if data and tags
    if tags.any?
      Event.create(name: 'processed_pdf', invoice: invoice)
    else
      EventError.create(name: 'processed_pdf', invoice: invoice, notes: 'OCR failed')
    end
  end

  def update_invoice
    if t=tags[:issue]
      invoice.date = text(t)
    end
    if t=tags[:due]
      invoice.due_date = text(t)
    end
    if t=tags[:subtotal]
      # Creates auxiliar line
      line = InvoiceLine.new(
        quantity: 1,
        description: 'Aux',
        price: decimal(t)
      )
      invoice.invoice_lines << line
    end
    if t=tags[:tax_percentage] and invoice.invoice_lines.any?
      invoice.invoice_lines.each do |invoice_line|
        tax = Tax.new(
          name: 'Aux',
          percent: decimal(t)
        )
        invoice_line.taxes << tax
      end
    end
    if invoice.is_a? ReceivedInvoice
      invoice.state=:received
    else
      invoice.state=:new
    end
    invoice.save(validate: false)
  end

  def tags
    data[:tags] || {}
  end

  def tokens
    data[:tokens] || {}
  end

  def text(token)
    data[:tokens][token][:text] rescue nil
  end

  # "€600.00"
  # "18,00%"
  def decimal(token)
    cents = text(token).gsub(/\D/,'').to_i
    cents / 100.0
  rescue
    0
  end
end
