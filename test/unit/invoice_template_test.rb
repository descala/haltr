require File.dirname(__FILE__) + '/../test_helper'

class InvoiceTemplateTest < ActiveSupport::TestCase
  
  fixtures :clients, :invoices, :invoice_lines, :projects

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
