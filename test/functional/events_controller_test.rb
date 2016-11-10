require File.dirname(__FILE__) + '/../test_helper'

class EventsControllerTest < ActionController::TestCase
  fixtures :companies, :invoices, :events

  def setup
    User.current = nil
  end

end
