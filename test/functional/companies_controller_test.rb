require File.dirname(__FILE__) + '/../test_helper'
require 'companies_controller'

# Re-raise errors caught by the controller.
class CompaniesController; def rescue_action(e) raise e end; end

class CompaniesControllerTest < ActionController::TestCase
  fixtures :projects, :enabled_modules, :users, :roles, :members, :companies

  def setup
    Setting.plugin_haltr = { 'trace_url' => 'loclhost:3000',
                             'export_channels_path' => '/tmp' }

    # user 2 (jsmith) is member of project 2 (onlinesotre)
    # with role 2 (developer)
    Project.find(2).enabled_modules << EnabledModule.new(:name => 'haltr')
    dev = Role.find(2)
    dev.permissions += [:general_use]
    assert dev.save

    @controller = CompaniesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
 end

  def test_show_edit_on_index
    @request.session[:user_id] = 2
    get :index, :id => 'onlinestore'
    assert_response :success
    assert_template 'edit'    
  end

end
