# encoding: utf-8
require File.expand_path('../../test_helper', __FILE__)

class OrderTest < ActiveSupport::TestCase

  include XsdValidator

  fixtures :invoices, :orders

  test "ubl invoice from order" do
    expected_invoice_xml =  File.read(File.dirname(__FILE__)+"/../../test/fixtures/documents/order_to_invoice_invoice.xml")
    order = orders(:order_001)
    assert order.xml?
    genreated_invoice_xml = order.ubl_invoice('3','2017-05-31')
    assert_equal expected_invoice_xml, genreated_invoice_xml

  end

  test "ubl order response" do
    order = orders(:order_001)
    xml = order.order_response("2017-07-13 18:28:00".to_time)
    # TODO suport UBL a XsdValidator
    # assert_equal [], xsd_validate(xml), xml
    expected_xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<OrderResponse xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" xmlns:qdt="urn:oasis:names:specification:ubl:schema:xsd:QualifiedDataTypes-2" xmlns:udt="urn:oasis:names:specification:ubl:schema:xsd:UnqualifiedDataTypes-2" xmlns="urn:oasis:names:specification:ubl:schema:xsd:OrderResponse-2">
  <cbc:UBLVersionID>2.1</cbc:UBLVersionID>
  <cbc:CustomizationID>urn:www.cenbii.eu:transaction:biitrns001:ver2.0:extended:urn:www.peppol.eu:bis:peppol28a:ver1.0</cbc:CustomizationID>
  <cbc:ProfileID>urn:www.cenbii.eu:profile:bii28:ver2.0</cbc:ProfileID>
  <cbc:ID>384386347</cbc:ID>
  <cbc:IssueDate>2017-07-13</cbc:IssueDate>
  <cbc:IssueTime>18:28:00</cbc:IssueTime>
  <cbc:OrderResponseCode listID="UNCL1225">29</cbc:OrderResponseCode>
  <cbc:DocumentCurrencyCode listID="ISO4217">GBP</cbc:DocumentCurrencyCode>
  <cac:OrderReference>
    <cbc:ID>94837593</cbc:ID>
  </cac:OrderReference>
  <cac:BuyerCustomerParty>
    <cac:Party>
      <cbc:EndpointID schemeID="GLN">4135811991839</cbc:EndpointID>
      <cac:PartyIdentification>
        <cbc:ID schemeID="GB:VAT">xxxx</cbc:ID>
      </cac:PartyIdentification>
      <cac:PartyName>
        <cbc:Name>Tech Hospitals NHS Trust</cbc:Name>
      </cac:PartyName>
    </cac:Party>
  </cac:BuyerCustomerParty>
  <cac:SellerSupplierParty>
    <cac:Party>
      <cbc:EndpointID schemeID="GLN">xxxx</cbc:EndpointID>
      <cac:PartyIdentification>
        <cbc:ID schemeID="GB:VAT">xxxx</cbc:ID>
      </cac:PartyIdentification>
      <cac:PartyName>
        <cbc:Name>CE Supplies UK Limited </cbc:Name>
      </cac:PartyName>
    </cac:Party>
  </cac:SellerSupplierParty>
</OrderResponse>
XML

    assert_equal expected_xml, xml
  end
end
