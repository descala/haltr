require File.dirname(__FILE__) + '/../test_helper'

class MailNotifierTest < ActiveSupport::TestCase

  include ActionDispatch::Assertions::SelectorAssertions

  def setup
    ActionMailer::Base.deliveries.clear
    Setting.host_name = 'mydomain.foo'
    Setting.protocol = 'http'
    Setting.plain_text_mail = '0'
  end

  def test_received_invoice_accepted
    invoice = Invoice.first
    reason = "reason"
    assert MailNotifier.received_invoice_accepted(invoice,reason).deliver
    assert_select_email do
      assert_select 'p', :text => 'Company1 accepted invoice number invoices_001'
      assert_select 'p', :text => 'reason'
    end
  end

  def test_received_invoice_refused
    invoice = Invoice.first
    reason = "reason"
    assert MailNotifier.received_invoice_refused(invoice,reason).deliver
    assert_select_email do
      assert_select 'p', :text => 'Company1 refused invoice number invoices_001'
      assert_select 'p', :text => 'reason'
    end
  end

  def test_invoice_paid
    invoice = Invoice.first
    assert_equal invoice.type, "IssuedInvoice"
    reason = "reason"
    assert MailNotifier.invoice_paid(invoice,reason).deliver
    assert_select_email do
      assert_select 'p', :text => 'Company1 has received payment for invoice number invoices_001'
      assert_select 'p', :text => 'reason'
    end
  end

end
