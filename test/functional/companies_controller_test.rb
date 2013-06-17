require File.dirname(__FILE__) + '/../test_helper'

class CompaniesControllerTest < ActionController::TestCase

  def test_edit_my_company_
    @request.session[:user_id] = 2
    get :my_company, :project_id => 'onlinestore'
    assert_response :success
    assert_template 'edit'    
  end

end
