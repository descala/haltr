# encoding: utf-8

require File.dirname(__FILE__) + '/../test_helper'

class HaltrMailHandlerTest < ActiveSupport::TestCase

  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures/mail_handler'

  def setup
    ActionMailer::Base.deliveries.clear
  end

  def teardown
    Setting.clear_cache
  end

  test "creates invoice from facturae32" do
    invoices = submit_email('invoice_facturae32_signed.eml')
    assert_invoices_created(invoices)
  end

  test "creates invoice from pdf" do
    invoices = submit_email('invoice_pdf_signed.eml')
    assert_invoices_created(invoices)
  end

  # TODO test does not create invoice when 
  #      recipient email cif is not the same in the xml

  private

  def submit_email(filename, options={})
    raw = IO.read(File.join(FIXTURES_PATH, filename))
    yield raw if block_given?
    HaltrMailHandler.receive(raw, options)
  end

  def assert_invoices_created(invoices)
    assert invoices.is_a?(Array), "Should return an array of invoices"
    assert invoices.size > 0, "Should return al least one invoice"
    i = 0
    invoices.each do |invoice|
      assert invoice.is_a?(Invoice), "invoices[#{i}] is not an Invoice. It is a #{invoice.class}"
      assert !invoice.new_record?
      invoice.reload
    end
  end
end
