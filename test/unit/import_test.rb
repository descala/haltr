require 'test_helper'

class ImportTest < ActiveSupport::TestCase
  
  fixtures  :invoices, :invoice_lines
  
  def setup
    importer = Import::Aeb43.new "test/files/aeb43.txt"
    @moviments = importer.moviments
  end
  
  
  def test_aeb43_import
    assert_kind_of Array, @moviments
    
    m = @moviments.shift
    assert_kind_of Import::Moviment, m
    assert_equal Date.strptime('01/01/09', '%d/%m/%y'), m.date_o
    assert_equal Date.strptime('01/01/09', '%d/%m/%y'), m.date_v
    assert_equal "FACTURA TARGETA CREDIT", m.txt1
    assert_equal Money.new(7721), m.amount
    
    m = @moviments.shift
    assert_equal Money.new(11791), m.amount
    assert_equal "B63456630", m.ref1        # tax id
    assert_equal "4660", m.ref2        # invoice number    
  end
  
  def test_match
    invoices = InvoiceDocument.all
  end
  
end
