# encoding: utf-8
require File.expand_path('../../test_helper', __FILE__)

class IssuedInvoiceTest < ActiveSupport::TestCase

  fixtures :clients, :invoices, :invoice_lines, :events

  def setup
    @project = Project.find 'onlinestore'
  end

  test "last invoice number" do
    num = IssuedInvoice.last_number(@project)
    assert_equal '2014/i14', num
  end

  test 'last sent envent' do
    i = IssuedInvoice.find 1
    assert_equal i.last_sent_event, events('with_file_notes')
  end

  test 'state updated at' do
    i = IssuedInvoice.find 4
    assert_equal 'new', i.state
    old_updated_at = i.updated_at
    assert_nil i.state_updated_at
    i.update_attribute(:state, 'sent')
    assert_not_nil i.state_updated_at, 'state modificication sets state_updated_at'
    old_state_updated_at = i.state_updated_at
    i.update_attribute(:state, 'closed')
    assert old_state_updated_at <  i.state_updated_at, 'state_updated_at updated whit state change'
    assert_equal old_updated_at, i.updated_at, 'updated_at does not change'
  end

  test 'AASM' do
    i = IssuedInvoice.find 4
    assert_equal 'new', i.state
    i.success_sending
    assert_equal 'sent', i.state
    i.registered_notification
    assert_equal 'registered', i.state
    i.accept_notification
    assert_equal 'accepted', i.state
    i.annotated_notification
    assert_equal 'annotated', i.state
    # does not change state in transition is invalid
    i.sent_notification
    assert_equal 'annotated', i.state
    # from inexistent state, raises exception
    i.state = 'accounted'
    i.save
    assert_equal 'accounted', i.state
    assert_raises AASM::UndefinedState do
      i.paid_notification
    end
  end

end
