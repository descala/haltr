# encoding: utf-8

require File.expand_path('../../test_helper', __FILE__)

class HaltrMailHandlerTest < ActiveSupport::TestCase

  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures/mail_handler'
  fixtures :invoices, :companies, :events

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
        :body => /transaction.id.=.*
                  &transaction.process.=Estructura%3A%3AInvoice
                  &transaction.invoice_id.=\d+
                  &transaction.payload.=.*
                  &transaction.vat_id.=77310058C
                  &transaction.is_issued.=false
                  &transaction.haltr_url.=http%3A%2F%2Flocalhost%3A3001/x,
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
    assert invoice.state == 'discarded', "Invoice final state is discarded (#{invoice.state})"
  end

  # TODO test does not create invoice when 
  #      recipient email cif is not the same in the xml

  private

  def submit_email(filename, options={})
    raw = IO.read(File.join(FIXTURES_PATH, filename))
    yield raw if block_given?
    Redmine::Configuration.with 'ws_url' => 'http://localhost:3000/api/v1/', 'haltr_url' => 'http://localhost:3001' do
      return HaltrMailHandler.receive(raw, options)
    end
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
