require File.dirname(__FILE__) + '/../../test_helper'

class Redmine::ApiTest::ClientsTest < Redmine::ApiTest::Base
  fixtures :companies, :clients

  def setup
    Setting.rest_api_enabled = '1'
  end

  test 'create' do
    assert_difference 'Client.count' do
      post '/projects/onlinestore/clients.xml',
        {"client"=>{"taxcode"=>"77310056h", "name"=>"Test","language"=>"en"}},
        credentials('jsmith')
      assert_response :created
      assert_equal 'application/xml', response.content_type
    end
    # now taxcode is in use
      post '/projects/onlinestore/clients.xml',
        {"client"=>{"taxcode"=>"77310056h", "name"=>"Test"}},
        credentials('jsmith')
    assert_response :unprocessable_entity
    assert_equal 'application/xml', response.content_type
    assert_tag 'errors', :child => {:tag => 'error', :content => "VAT Id Number has already been taken"}
  end

  test 'show' do
    get '/clients/1.json', {}, credentials('jsmith')
    assert_response :success
    assert_equal 'A13585625', JSON(response.body)['client']['taxcode']
  end

  test 'index' do
    get '/projects/onlinestore/clients.json', {}, credentials('jsmith')
    assert_response :success
    assert_equal 'A13585625', JSON(response.body)['clients'].first['taxcode']
  end

  test 'delete' do
    assert_difference('Client.count', -1) do
      delete '/clients/1.json', {}, credentials('jsmith')
      assert_response :success
      assert_equal '', response.body
    end
    assert_nil Client.find_by_id(1)
  end
end
