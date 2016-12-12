require File.dirname(__FILE__) + '/../../test_helper'

class Redmine::ApiTest::EventsTest < Redmine::ApiTest::Base
  fixtures :invoices, :events

  def setup
    Setting.rest_api_enabled = '1'
  end

  test 'create event' do
    assert_equal('sent', Invoice.find(1).state)

    post '/events.json', {
      event: {
        invoice_id: 1,
        name: 'registered_notification',
        type: 'Event'
      }
    }
    assert_response :created
    assert_equal('registered', Invoice.find(1).state)
  end

end
