require File.expand_path('../../test_helper', __FILE__)

class InvoiceTest < ActiveSupport::TestCase

  fixtures :clients, :invoices, :invoice_lines, :taxes, :companies, :people, :bank_infos

  test "stores and retrives original files as base64 compressed strings" do
    text = 'this text should be compressed. ' * 10
    i = invoices :received_1
    assert i.is_a? ReceivedInvoice
    i.original = text
    assert_equal text, i.original
    compressed = i.read_attribute(:original)
    assert compressed != text
    assert compressed.size <  i.original.size
  end 

  test 'without lines' do
    invoice = ReceivedInvoice.new({
      project_id: 2,
      client: clients(:clients_001),
      date: '2314sadifj',
      currency: nil,
      number: '1234',
      import: 1000.to_money(:eur),
      total:  1210.to_money(:eur)
    })

    invoice.save!

    assert invoice.valid?
    assert_equal 1000.to_money(:eur), invoice.import
    assert_equal 1210.to_money(:eur), invoice.total
  end
end 
