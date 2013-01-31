require File.dirname(__FILE__) + '/../test_helper'
require 'invoices_controller'

# Re-raise errors caught by the controller.
class InvoicesController; def rescue_action(e) raise e end; end

class InvoicesControllerTest < ActionController::TestCase
  fixtures :projects, :enabled_modules, :users, :roles, :members, :invoices, :companies

  include Haltr::XmlValidation

  def setup

    Setting.plugin_haltr = { "trace_url"=>"http://localhost:3001", "b2brouter_ip"=>"", "export_channels_path"=>"/tmp", "default_country"=>"es", "default_currency"=>"EUR", "issues_controller_name"=>"issues" }

    # user 2 (jsmith) is member of project 2 (onlinesotre)
    # with role 2 (developer)
    Project.find(2).enabled_modules << EnabledModule.new(:name => 'haltr')
    dev = Role.find(2)
    dev.permissions += [:general_use]
    r = dev.save

    assert r

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
    assert_redirected_to :controller => 'companies', :action => 'index', :id => 'onlinestore'
  end

  test 'facturae_xml' do
    @request.session[:user_id] = 2
    get :facturae30, :id => 1
    xml = @response.body
    assert_equal [], facturae_errors(xml)
    get :facturae31, :id => 1
    xml = @response.body
    assert_equal [], facturae_errors(xml)
    get :facturae32, :id => 1
    xml = @response.body
    assert_equal [], facturae_errors(xml)
  end

  test 'biiubl20_xml' do
    get :biiubl20, :id => 1
    xml = @response.body
    assert_equal [], ubl_errors(xml)
  end


end
