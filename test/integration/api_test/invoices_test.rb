require File.dirname(__FILE__) + '/../../test_helper'

class Redmine::ApiTest::InvoicesTest < Redmine::ApiTest::Base
  fixtures :companies, :invoices, :invoice_lines, :taxes

  def setup
    Setting.rest_api_enabled = '1'
  end

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

  test 'shows invoice' do
    get '/invoices/6.json', {}, credentials('jsmith')
    assert_response :success
    assert_equal 'new', JSON(response.body)['invoice']['state']
#    get '/invoices/6', nil, {"Accept" => "application/json", "X-Requested-With" => "XMLHttpRequest"}.merge(credentials('jsmith'))
#    assert_response :success
#    assert_equal 'adsf', response.body
  end

  test 'shows download_legal_url' do
    get '/invoices/1.json', {}, credentials('jsmith')
    assert_response :success
    assert_equal '/events/file/524484085', JSON(response.body)['invoice']['download_legal_url']
    #puts JSON.pretty_generate(JSON(response.body))
  end

  test 'invoice index' do
    get '/projects/onlinestore/invoices.json', {}, credentials('jsmith')
    assert_response :success
    assert_equal '2013-02-05', JSON(response.body)['invoices'].first['due_date']
  end

  test 'delete' do
    assert_difference('IssuedInvoice.count', -1) do
      delete '/invoices/6.json', {}, credentials('jsmith')
      assert_response :success
      assert_equal '', response.body
    end
    assert_nil Invoice.find_by_id(6)
  end
end
