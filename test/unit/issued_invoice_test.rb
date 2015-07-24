# encoding: utf-8
require File.dirname(__FILE__) + '/../test_helper'

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

end
