# encoding: utf-8
require File.expand_path('../../test_helper', __FILE__)

class OrderTest < ActiveSupport::TestCase

  fixtures :invoices

  test "ubl invoice from order" do
    order_xml = File.read(File.dirname(__FILE__)+"/../../test/fixtures/documents/order_to_invoice_order.xml")
    expected_invoice_xml =  File.read(File.dirname(__FILE__)+"/../../test/fixtures/documents/order_to_invoice_invoice.xml")
    order = Order.new(
      project_id: 2,
      original: order_xml,
    )
    assert order.xml?
    genreated_invoice_xml = order.ubl_invoice('3','2017-05-31')
    assert_equal expected_invoice_xml, genreated_invoice_xml

  end
end
