require File.expand_path('../../../test_helper', __FILE__)

class SendOrderResponseByPeppolTest < ActiveSupport::TestCase

  fixtures :orders

  test "sends order response by Peppol" do

    stub = stub_request(:post, "#{Redmine::Configuration['ws_url']}transactions").
      with(body: /haltr_object_type.=Order/x).
      to_return(status: 200, body: '{"id":"1234"}')

    events_count = Event.count
    order = orders(:order_001)
    assert_match(/OrderResponse/, order.order_response)
    sender = Haltr::SendOrderResponseByPeppol.new(
      order: order, channel: :peppolbis21_test, user: User.find(1)
    )
    sender.immediate_perform(order.order_response)
    assert_requested(stub)
    events_count += 1
    assert_equal events_count, Event.count
    assert_equal HiddenEvent, Event.last.class
  end

end

