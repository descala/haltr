require File.expand_path('../../test_helper', __FILE__)

class InvoiceImgTest < ActiveSupport::TestCase

  fixtures :invoices, :events

  test "requires an invoice" do
    assert !InvoiceImg.new.save, "should not save without an invoice"
    assert !InvoiceImg.new(:invoice_id=>99999).save, "should not save without an invoice"
    assert InvoiceImg.new(:invoice_id=>invoices(:i15).id).save
  end

  test "on create updates invoice status and creates an event" do
    invoice = invoices(:i15)
    assert_equal "processing_pdf", invoice.state
    num_events = invoice.events.size
    assert_equal num_events, invoice.events.size
    assert InvoiceImg.new(invoice: invoice).save
    invoice.reload
    assert_equal "new", invoice.state
    assert_equal num_events+1, invoice.events.size
  end

end
