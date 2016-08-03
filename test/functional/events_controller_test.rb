require File.expand_path('../../test_helper', __FILE__)

class EventsControllerTest < ActionController::TestCase
  fixtures :companies, :invoices, :events

  def setup
    User.current = nil
  end

  test 'event authorize' do
    event_id = events('with_file').id
    # jsmith
    @request.session[:user_id] = 2
    get :file, id: event_id
    assert_response :success
    # dlopper has no access to project
    @request.session[:user_id] = 3
    get :file, id: event_id
    assert_response 403
  end 
end
