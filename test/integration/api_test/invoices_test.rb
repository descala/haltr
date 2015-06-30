require File.dirname(__FILE__) + '/../../test_helper'

class Redmine::ApiTest::AttachmentsTest < Redmine::ApiTest::Base
  fixtures :companies, :invoices, :invoice_lines, :taxes

  test 'creates invoce from facturae' do

    assert_difference 'IssuedInvoice.count' do
      post '/projects/onlinestore/invoices/facturae.xml', fixture_file_upload('/documents/invoice_facturae32_issued.xml') , {"CONTENT_TYPE" => 'application/octet-stream'}.merge(credentials('jsmith'))
      assert_response :created 
      assert_equal 'application/xml', response.content_type
    end
    # now invoice.number is in use
    post '/projects/onlinestore/invoices/facturae.xml', fixture_file_upload('/documents/invoice_facturae32_issued.xml') , {"CONTENT_TYPE" => 'application/octet-stream'}.merge(credentials('jsmith'))

    assert_response :unprocessable_entity
    assert_equal 'application/xml', response.content_type
    assert_tag 'errors', :child => {:tag => 'error', :content => "Number has already been taken"}
  end

end
