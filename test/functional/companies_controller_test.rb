require File.dirname(__FILE__) + '/../test_helper'
require 'companies_controller'

# Re-raise errors caught by the controller.
class CompaniesController; def rescue_action(e) raise e end; end

class CompaniesControllerTest < ActionController::TestCase
  fixtures :companies

  def setup
    @controller = CompaniesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    Haltr::TestHelper.haltr_setup
 end

  def test_show_edit_on_index
    @request.session[:user_id] = 2
    get :index, :id => 'onlinestore'
    assert_response :success
    assert_template 'edit'    
  end

end
