require File.expand_path('../../test_helper', __FILE__)

class EventsControllerTest < ActionController::TestCase
  fixtures :companies, :invoices, :events

  def setup
    User.current = nil
    @request.session[:user_id] = 2
  end

end
