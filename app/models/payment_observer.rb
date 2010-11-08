class PaymentObserver < ActiveModel::Observer
  unloadable

  def after_save(payment)
    invoice = payment.invoice
    return unless invoice
    if invoice.total_paid >= invoice.price_in_cents
      invoice.status = Invoice::STATUS_CLOSED
      invoice.save
    end
  end

end
