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
end
