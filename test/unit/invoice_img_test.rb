require File.expand_path('../../test_helper', __FILE__)

class InvoiceImgTest < ActiveSupport::TestCase

  fixtures :invoices, :invoice_lines, :events, :invoice_imgs

  test "requires an invoice" do
    assert !InvoiceImg.new.save, "should not save without an invoice"
    assert !InvoiceImg.new(:invoice_id=>99999).save, "should not save without an invoice"
    assert InvoiceImg.new(:invoice_id=>invoices(:i15).id).save!
  end

  test "on create updates invoice status and creates an event" do
    invoice = invoices(:i15)
    assert_equal "processing_pdf", invoice.state
    num_events = invoice.events.size
    assert_equal num_events, invoice.events.size
    assert InvoiceImg.new(invoice: invoice).save!
    invoice.reload
    assert_equal num_events+1, invoice.events.size
  end

  test "updates invoice with our data" do
    invoice_img = invoice_imgs(:image1)
    assert_equal Hash, invoice_img.data.class
    invoice_img.update_invoice
    invoice = invoice_img.invoice
    assert_equal 1, invoice.invoice_lines.count
    assert_equal 60000, invoice.import_in_cents
    assert_equal "01-06-2012".to_date, invoice.due_date
    assert_equal :received, invoice.state
  end
end
