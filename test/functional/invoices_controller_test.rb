require File.dirname(__FILE__) + '/../test_helper'
require 'invoices_controller'

# Re-raise errors caught by the controller.
class InvoicesController; def rescue_action(e) raise e end; end

class InvoicesControllerTest < ActionController::TestCase
  fixtures :companies

  include Haltr::XmlValidation

  def setup
    @controller = InvoicesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 2
  end

  test "must_redirect_if_not_configured" do
    # deconfigure onlinestore
    companies(:company1).destroy
    @request.session[:user_id] = 2
    get :index, :id => 'onlinestore'
  end

  test 'facturae30' do
    @request.session[:user_id] = 2
    get :facturae30, :id => 4
    assert_response :success
    xml = @response.body
    assert xml
    assert_equal [], facturae_errors(xml)
  end

  test 'facturae31' do
    @request.session[:user_id] = 2
    get :facturae31, :id => 4
    assert_response :success
    xml = @response.body
    assert xml
    assert_equal [], facturae_errors(xml)
  end

  test 'facturae32' do
    @request.session[:user_id] = 2
    get :facturae32, :id => 4
    assert_response :success
    xml = @response.body
    assert xml
    assert_equal [], facturae_errors(xml)
  end

  # uses invoice 'i4'
  test 'biiubl20_xml_i4' do
    get :biiubl20, :id => 4
    assert_response :success
    xml = @response.body
    assert_equal [], ubl_errors(xml,false)
  end

  # uses invoice 'i5'
  test 'biiubl20_xml_i5_vat_excemption' do
    get :biiubl20, :id => 5
    assert_response :success
    xml = @response.body
    assert_equal [], ubl_errors(xml,true)
  end


end
