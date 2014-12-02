# encoding: utf-8

require File.dirname(__FILE__) + '/../test_helper'

class HaltrMailHandlerTest < ActiveSupport::TestCase

  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures/mail_handler'
  fixtures :invoices

  def setup
    ActionMailer::Base.deliveries.clear
  end

  def teardown
    Setting.clear_cache
  end

  test "creates invoice from facturae32" do
    # create, it may exist (same md5)
    invoices = submit_email('invoice_facturae32_signed.eml')
    assert_invoices_created(invoices)
    # delete and create again
    assert invoices.first.destroy
    invoices = submit_email('invoice_facturae32_signed.eml')
    assert_invoices_created(invoices)
  end

  test "creates invoice from mail with attached pdf" do

    stub_request(:post, "http://localhost:3000/api/v1/transactions").
      with(
        :body => /transaction.id.=1f2e767e4cf28f53e8239b506475add6
                  &transaction.process.=Estructura%3A%3AInvoice
                  &transaction.invoice_id.=\d+
                  &transaction.payload.=.*
                  &transaction.vat_id.=77310058H
                  &transaction.is_issued.=false
                  &transaction.haltr_url.=http%3A%2F%2Flocalhost%3A3001
                  &token=f1c9296ec8cb35b02eeea064c720c168/x,
    ).to_return(:status => 200,
                :body => "",
                :headers => {})

    # create, it may exist (same md5)
    invoices = submit_email('invoice_pdf_signed.eml')
    assert_invoices_created(invoices)
    assert(invoices.first.is_a?(ReceivedInvoice))
    # delete and create again
    assert invoices.first.destroy
    invoices = submit_email('invoice_pdf_signed.eml')
    assert_invoices_created(invoices)
    assert(invoices.first.is_a?(ReceivedInvoice))
    assert(invoices.first.original)
  end

  test "takes in account all recipients" do
    invoices = submit_email('invoice_facturae32_with_many_recipients.eml')
    assert_invoices_created(invoices)
  end

  test 'processes bounce and updates invoice' do
    assert Invoice.find(2).state == 'sent', "Invoice initial state is sent (#{Invoice.find(2).state})"
    invoices = submit_email('invoice_bounce.eml')
    assert invoices.size == 1, "it finds 1 invoice (#{invoices.size})"
    invoice = invoices.first
    assert invoice.events.last.name == 'bounced', "it creates an event for the bounce (last event: #{invoice.events.last.name})"
    assert invoice.state == 'discarded', "Invoice dinal state is discarded (#{invoice.state})"
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
