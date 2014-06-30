require File.dirname(__FILE__) + '/../test_helper'

class EventTest < ActiveSupport::TestCase
  fixtures :events

  test "has a to_s method" do
    assert_equal "Edited by John Smith", events('invoices_001_edited').to_s
    assert_equal "Delivery order given by John Smith", events('invoices_001_queue').to_s
    assert_equal "Manually marked as sent by John Smith", events('invoices_001_manual_send').to_s
  end
end
