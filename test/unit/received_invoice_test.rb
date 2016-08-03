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

end 
