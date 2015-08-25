require File.dirname(__FILE__) + '/../test_helper'

class InvoicesHelperTest < ActionView::TestCase

  include Redmine::I18n

  fixtures :clients, :invoices, :invoice_lines, :taxes, :companies, :bank_infos

  test "payment_method_info with long IBAN" do
    @invoice = IssuedInvoice.find(7)
    assert_match(/IBAN FR76 1009 6185 1700 0497 1540 147/, payment_method_info)
  end

  # define alias for escape_javascript
  def j(s)
    s
  end

  test "send_link_for_invoice handles unknown Client#invoice_format" do
    @invoice = invoices(:invoice1)
    client = @invoice.client
    client.invoice_format = 'white_crow'
    client.save
    ExportChannels.use_file('channels.yml.example')
    assert_match(/Signed PDF to email.*Cannot re-send invoices in state Sent/m, send_link_for_invoice)
  end
end
