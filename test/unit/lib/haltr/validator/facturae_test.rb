require File.expand_path('../../../../../test_helper', __FILE__)

class FacturaeTest < ActiveSupport::TestCase

  fixtures :clients, :invoices

  test "invoices validate with Haltr::Validator::Facturae when applies" do
    client = clients(:client1)
    assert 'B10317980', client.taxcode
    invoice = invoices(:invoice1)
    assert invoice.valid?, invoice.errors.full_messages.join
    assert client.valid?, client.errors.full_messages.join
    client.update_column :postalcode, ''
    assert_equal '', client.postalcode
    assert client.valid?, client.errors.full_messages.join
    invoice.reload
    assert invoice.valid?
    invoice.about_to_be_sent=true
    assert !invoice.valid?, 'invoice is valid but client postalcode is blank'
    assert_equal 'Client Postcode cannot be blank', invoice.errors.full_messages.join
  end

end
