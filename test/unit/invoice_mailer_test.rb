require File.dirname(__FILE__) + '/../test_helper'

class InvoiceMailerTest < ActiveSupport::TestCase

  include ActionDispatch::Assertions::SelectorAssertions

  def setup
    ActionMailer::Base.deliveries.clear
  end

  def test_issued_invoice_mail
    invoice = Invoice.first
    assert_equal invoice.type, "IssuedInvoice"
    assert InvoiceMailer.issued_invoice_mail(invoice).deliver
  end

end
