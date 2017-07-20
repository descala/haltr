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
    assert_response :created, @response.body
    assert_equal('registered', Invoice.find(1).state)
  end

  test "accepta events polimorfics" do
    event_count = Event.count

    post '/events.json', {
      event: {
        type: 'Event',
        model_object_id: '1',
        model_object_type: 'Invoice',
        name: 'success_sending'
      }
    }

    assert_response :success
    event_count +=1
    assert_equal event_count, Event.count

    post '/events.json', {
      event: {
        project_id: 1,
        type: 'Event',
        model_object_id: '1',
        model_object_type: 'Nonexist',
        name: 'success_sending'
      }
    }
    assert_response :unprocessable_entity
    assert_match(/Unknown type: Nonexist/, @response.body)
    assert_equal event_count, Event.count

  end

  test "accepta events polimorfics amb nils" do
    event_count = Event.count

    post '/events.json', {
      event: {
        type: 'Event',
        invoice_id: '1',
        model_object_id: '',
        model_object_type: '',
        name: 'success_sending'
      }
    }

    assert_response :success
    event_count +=1
    assert_equal event_count, Event.count
  end

end
