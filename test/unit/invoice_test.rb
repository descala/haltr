require File.dirname(__FILE__) + '/../test_helper'

class InvoiceTest < ActiveSupport::TestCase

  fixtures :clients, :invoices, :invoice_lines, :projects, :taxes

  def setup
    Setting.plugin_haltr = { "trace_url"=>"http://localhost:3001", "b2brouter_ip"=>"", "export_channels_path"=>"/tmp", "default_country"=>"es", "default_currency"=>"EUR", "issues_controller_name"=>"issues" }
  end

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
    assert_equal Date.new(2008,12,1), i.due_date
  end
 
  test "invoice number increment right" do
    assert_equal "not_an_i1", IssuedInvoice.increment_right("not_an_i")
    assert_equal "1", IssuedInvoice.increment_right(nil)
    assert_equal "2011/2", IssuedInvoice.increment_right("2011/1")
    assert_equal "2011-2", IssuedInvoice.increment_right("2011-1")
    assert_equal "11/002", IssuedInvoice.increment_right("11/001")
    assert_equal "0032", IssuedInvoice.increment_right("0031")
    assert_equal "1000", IssuedInvoice.increment_right("999")
  end

  test "sort draft invoices" do
    assert_equal -1 , invoices(:draft) <=> invoices(:invoice1)
    assert_equal 1 , invoices(:invoice1) <=> invoices(:draft)
    assert_equal 0 , invoices(:draft) <=> invoices(:draft)
  end

  test "invoice contable validation" do
    assert_equal 100, invoices(:invoices_003).subtotal_without_discount.dollars
    assert_equal 100, invoices(:invoices_003).taxable_base.dollars
    assert_equal 18, invoices(:invoices_003).tax_amount.dollars
    assert_equal 1, invoices(:invoices_003).taxes_uniq.size
    assert_equal 100, invoices(:invoices_003).subtotal.dollars
    assert_equal 0, invoices(:invoices_003).discount.dollars
    assert_equal 0, invoices(:invoices_003).discount_without_expenses.dollars
    assert_equal 118, invoices(:invoices_003).total.dollars
    assert_equal "J", invoices(:invoices_003).persontypecode

    assert_equal 100, invoices(:invoices_002).subtotal_without_discount.dollars
    assert_equal 85, invoices(:invoices_002).taxable_base.dollars
    assert_equal 15.30, invoices(:invoices_002).tax_amount.dollars
    assert_equal 1, invoices(:invoices_002).taxes_uniq.size
    assert_equal 85, invoices(:invoices_002).subtotal.dollars
    assert_equal 15, invoices(:invoices_002).discount.dollars
    assert_equal 15, invoices(:invoices_002).discount_without_expenses.dollars
    assert_equal 100.30, invoices(:invoices_002).total.dollars
    assert_equal "J", invoices(:invoices_002).persontypecode

    assert_equal 250, invoices(:invoices_001).subtotal_without_discount.dollars
    assert_equal 225, invoices(:invoices_001).taxable_base.dollars
    assert_equal 2.7, invoices(:invoices_001).tax_amount.dollars
    assert_equal -13.5, invoices(:invoices_001).tax_amount(taxes(:taxes_006)).dollars
    assert_equal 16.2, invoices(:invoices_001).tax_amount(taxes(:taxes_005)).dollars
    assert_equal 7.2, invoices(:invoices_001).tax_amount(taxes(:taxes_007)).dollars
    assert_equal -7.2, invoices(:invoices_001).tax_amount(taxes(:taxes_008)).dollars
    assert_equal 4, invoices(:invoices_001).taxes_uniq.size
    assert_equal 225, invoices(:invoices_001).subtotal.dollars
    assert_equal 25, invoices(:invoices_001).discount.dollars
    assert_equal 20, invoices(:invoices_001).discount_without_expenses.dollars
    assert_equal 227.7, invoices(:invoices_001).total.dollars
    assert_equal "F", invoices(:invoices_001).persontypecode
  end

  test "currency to upcase" do
    i=invoices(:invoices_003)
    assert_equal "EUR", i.currency
    i.currency="usd"
    assert_equal "USD", i.currency
  end

  test "tax_categories" do
    i=invoices(:invoices_001)
    categories = i.tax_categories
    assert_equal 3, categories.size
    assert_equal 1, categories["AA"].size
    assert_equal 8, categories["AA"].first.percent
    assert_equal 1, categories["S"].size
    assert_equal 18, categories["S"].first.percent
    assert_equal 2, categories["E"].size
    e_percents = categories["E"].collect {|t| t.percent }
    assert e_percents.include? 8
    assert e_percents.include? 18
  end

end
