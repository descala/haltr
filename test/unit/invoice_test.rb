require File.dirname(__FILE__) + '/../test_helper'

class InvoiceTest < ActiveSupport::TestCase
  
  fixtures :clients, :invoices, :invoice_lines, :projects

  test "due dates" do
    date = Date.new(2000,12,1)
    i = IssuedInvoice.new(:client=>clients(:client1),:project=>projects(:projects_002),:date=>date,:number=>1)
    i.invoice_lines << invoice_lines(:invoice1_l1)
    i.save!
    assert_equal date, i.due_date
    i = IssuedInvoice.new(:client=>clients(:client1),:project=>projects(:projects_002),:date=>date,:number=>2,:terms=>"1m15")
    i.invoice_lines << invoice_lines(:invoice1_l1)
    i.save!
    assert_equal Date.new(2001,1,15), i.due_date
    i = IssuedInvoice.new(:client=>clients(:client1),:project=>projects(:projects_002),:date=>date,:number=>3,:terms=>"3m15")
    i.invoice_lines << invoice_lines(:invoice1_l1)
    i.save!
    assert_equal Date.new(2001,3,15), i.due_date
  end

  test "do not modify due dates on save" do
    i = invoices(:invoice1)
    d = Date.new(2010,1,1)
    i.due_date = d
    i.save!
    i = Invoice.find i.id
    assert_equal d, i.due_date
  end
 
  test "invoice number increment right" do
    assert_equal "not_an_i1", IssuedInvoice.increment_right("not_an_i")
    assert_equal "1", IssuedInvoice.increment_right(nil)
    assert_equal "2011/2", IssuedInvoice.increment_right("2011/1")
    assert_equal "2011-2", IssuedInvoice.increment_right("2011-1")
    assert_equal "11/002", IssuedInvoice.increment_right("11/001")
    assert_equal "0032", IssuedInvoice.increment_right("0031")
    assert_equal "999", IssuedInvoice.increment_right("1000")
  end

end
