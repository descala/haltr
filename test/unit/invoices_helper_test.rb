require File.dirname(__FILE__) + '/../test_helper'

class InvoicesHelperTest < ActionView::TestCase

  include Redmine::I18n

  fixtures :clients, :invoices, :invoice_lines, :taxes, :companies, :bank_infos

  test "payment_method_info with long IBAN" do
    @invoice = IssuedInvoice.find(7)
    assert_match(/IBAN FR76 1009 6185 1700 0497 1540 147/, payment_method_info)
  end
end
