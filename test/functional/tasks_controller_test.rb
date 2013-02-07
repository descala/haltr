require File.dirname(__FILE__) + '/../test_helper'
require 'tasks_controller'

# Re-raise errors caught by the controller.
class TasksController; def rescue_action(e) raise e end; end

class TasksControllerTest < ActionController::TestCase
  fixtures :clients, :invoices, :invoice_lines, :projects, :taxes, :companies

  def setup
    @controller = TasksController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    Haltr::TestHelper.haltr_setup
    Haltr::TestHelper.fix_invoice_totals
  end

  def test_n19
    @request.session[:user_id] = 2
    get :n19, :id => invoices('invoice1')
    assert_response :success
    assert_template 'n19.rhtml'
    assert_not_nil assigns(:due_date)
    assert_equal 'text/plain', @response.content_type
    lines = @response.body.chomp.split("\n")
    # spaces are relevant
    assert_equal '568077310000G000B00000000   SOME NON ASCII CHARS  LONG NAME THAT MAY114910865126953221150000092568                FRA 08/001                        925,68        ', lines[2]
  end

end
