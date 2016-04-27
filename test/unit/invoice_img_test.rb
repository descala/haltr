require File.expand_path('../../test_helper', __FILE__)

class InvoiceImgTest < ActiveSupport::TestCase

  fixtures :invoices, :invoice_lines, :events, :invoice_imgs, :clients

  test "requires an invoice" do
    assert !InvoiceImg.new.save, "should not save without an invoice"
    assert !InvoiceImg.new(:invoice_id=>99999).save, "should not save without an invoice"
    assert InvoiceImg.new(:invoice_id=>invoices(:i15pdf).id).save!
  end

  test "on create updates invoice status and creates an event" do
    invoice = invoices(:i15pdf)
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

  test "fuzzy_match_client" do
    invoice_img = invoice_imgs(:image1)
    assert_equal clients(:client1), invoice_img.fuzzy_match_client
    assert_equal 69, invoice_img.tags['seller_taxcode']
    assert_equal 70, invoice_img.tags['buyer_taxcode']
  end

  test "ensure keys are symbols" do
    invoice_img = invoice_imgs(:image1)
    assert_equal 'Hash', invoice_img.data.class.to_s
    assert_equal 'Hash', invoice_img.data[:tags].class.to_s
    assert_equal 66, invoice_img.data[:tags][:subtotal]
    assert_equal 'Hash', invoice_img.data[:tokens].class.to_s
    assert_equal 'Hash', invoice_img.data[:tokens][66].class.to_s
    assert_equal "€600.00", invoice_img.data[:tokens][66][:text]
    assert_equal 597, invoice_img.data[:tokens][66][:x0]
  end
end
