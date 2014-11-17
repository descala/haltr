# encoding: utf-8
require File.dirname(__FILE__) + '/../test_helper'

class IssuedInvoiceTest < ActiveSupport::TestCase

  fixtures :clients, :invoices, :invoice_lines, :taxes, :companies, :people, :bank_infos

  test "last invoice number" do
    project = Project.find 'onlinestore'
    num = IssuedInvoice.last_number(project)
    assert_equal '2014/i12', num
  end
end
