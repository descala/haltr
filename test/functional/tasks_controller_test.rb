require File.dirname(__FILE__) + '/../test_helper'
require 'tasks_controller'

# Re-raise errors caught by the controller.
class TasksController; def rescue_action(e) raise e end; end

class TasksControllerTest < ActionController::TestCase
  fixtures :projects, :enabled_modules, :users, :roles, :members, :invoices, :companies

  def setup
    # user 2 (jsmith) is member of project 2 (onlinesotre)
    # with role 2 (developer)
    Project.find(2).enabled_modules << EnabledModule.new(:name => 'haltr')
    dev = Role.find(2)
    dev.permissions += [:general_use]
    assert dev.save
    @controller = TasksController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
 end

  def test_n19
    @request.session[:user_id] = 2
    get :n19, :id => invoices('invoice1')
    assert_response :success
    assert_template 'n19.rhtml'
    assert_not_nil assigns(:due_date)
    assert_equal 'text', @response.content_type
    lines = @response.body.chomp.split("\n")
    # spaces are relevant
    assert_equal '568077310000G000B00000000   SOME NON ASCII CHARS  LONG NAME THAT MAY114910865126953221150000109230                FRA 08/001                      1.092,30        ', lines[2]
  end

end
