require File.dirname(__FILE__) + '/../test_helper'
require 'invoices_controller'

# Re-raise errors caught by the controller.
class InvoicesController; def rescue_action(e) raise e end; end

class InvoicesControllerTest < ActionController::TestCase
  fixtures :companies, :invoices, :invoice_lines, :taxes

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
    Invoice.find(4).save!
    @request.session[:user_id] = 2
    get :facturae30, :id => 4
    assert_response :success
    xml = @response.body
    assert xml
    assert_equal [], facturae_errors(xml)
  end

  test 'facturae31' do
    Invoice.find(2).save!
    @request.session[:user_id] = 2
    get :facturae31, :id => 4
    assert_response :success
    xml = @response.body
    assert xml
    assert_equal [], facturae_errors(xml)
  end

  test 'facturae32' do
    Invoice.find(2).save!
    @request.session[:user_id] = 2
    get :facturae32, :id => 4
    assert_response :success
    xml = @response.body
    assert xml
    assert_equal [], facturae_errors(xml)
  end

  test 'facturae_xml_i5_vat_excemption' do
    Invoice.find(5).save!
    get :facturae32, :id => 5
    assert_response :success
    xml = @response.body
    assert_equal [], facturae_errors(xml)
  end

  test 'facturae_xml_i6_vat_and_charges' do
    Invoice.find(6).save!
    get :facturae32, :id => 6
    assert_response :success
    xml = @response.body
    assert_equal [], facturae_errors(xml)
  end

  test 'facturae_xml_i7_vat_10_vat_20_and_charges' do
    Invoice.find(7).save!
    get :facturae32, :id => 7
    assert_response :success
    xml = @response.body
    assert_equal [], facturae_errors(xml)
  end

  test 'biiubl20_xml_i4' do
    Invoice.find(4).save!
    get :biiubl20, :id => 4
    assert_response :success
    xml = @response.body
    assert_equal [], ubl_errors(xml)
  end

  test 'biiubl20_xml_i5_vat_excemption' do
    Invoice.find(5).save!
    get :biiubl20, :id => 5
    assert_response :success
    xml = @response.body
    assert_equal [], ubl_errors(xml)
  end

  test 'biiubl20_xml_i6_vat_and_charges' do
    Invoice.find(6).save!
    get :biiubl20, :id => 6
    assert_response :success
    xml = @response.body
    assert_equal [], ubl_errors(xml)
  end

  test 'peppolubl20_xml_i7_vat_10_vat_20_and_charges' do
    Invoice.find(7).save!
    get :peppolubl20, :id => 7
    assert_response :success
    xml = @response.body
    assert_equal [], ubl_errors(xml)
  end

end
