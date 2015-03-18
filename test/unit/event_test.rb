require File.dirname(__FILE__) + '/../test_helper'

class EventTest < ActiveSupport::TestCase
  fixtures :events, :invoices

  test "has a to_s method" do
    assert_equal "Edited by John Smith", events('invoices_001_edited').to_s
    assert_equal "Delivery order given by John Smith", events('invoices_001_queue').to_s
    assert_equal "Manually marked as sent by John Smith", events('invoices_001_manual_send').to_s
  end

  test 'updates invoice' do
    invoice = invoices(:invoice1)
    assert_equal 'sent', invoice.state
    Event.create(
      name: 'refuse_notification',
      invoice: invoice,
    )
    invoice.reload
    assert_equal 'refused', invoice.state
    # to allow this modify "event :bounced" on IssuedInvoice
    assert_raise StateMachine::InvalidTransition do
      Event.create(
        name: 'bounced',
        invoice: invoice,
      )
    end
    invoice.reload
    assert_equal 'refused', invoice.state
  end
end
