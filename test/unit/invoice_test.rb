require File.dirname(__FILE__) + '/../test_helper'

class InvoiceTest < ActiveSupport::TestCase
  
  fixtures :clients, :invoices

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
  
  test "template_replacements" do
    I18n.locale = :ca
    it = invoices(:template1)
    it.template_replacements(Date.new(2008,1,15))
    assert_equal "periode: Febrer 2008", it.extra_info
    it.frequency = 12
    it.template_replacements(Date.new(2008,1,15))    
    assert_equal "periode: Gener 2009", it.extra_info
  end

  test "next invoice" do
    I18n.locale = :ca
    it = invoices(:template1)
    ni = it.next_invoice
    assert_equal "periode: Desembre 2008", ni.extra_info
    ni = it.next_invoice
    assert_equal "periode: Gener 2009", ni.extra_info
  end
  
end
