require File.dirname(__FILE__) + '/../test_helper'

class ReceivedControllerTest < ActionController::TestCase
  fixtures :companies, :invoices, :invoice_lines, :taxes

  def setup
    User.current = nil
    @request.session[:user_id] = 2
  end

  test "show received pdf invoice" do
    get :show, :id => invoices(:received_1)
  end

  test "show accpeted xml invoice" do
    get :show, :id => invoices(:received_2)
  end

end
