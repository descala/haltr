require File.dirname(__FILE__) + '/../test_helper'

class ImportTest < ActiveSupport::TestCase
  
  def setup
    assert 'EUR', Setting.plugin_haltr['default_currency']
    filename = File.dirname(__FILE__) + '/../fixtures/txt/aeb43.txt'
    importer = Import::Aeb43.new filename
    @moviments = importer.moviments
  end
  
  
  def test_aeb43_import
    assert_kind_of Array, @moviments
    
    m = @moviments.shift
    assert_kind_of Import::Moviment, m
    assert_equal Date.strptime('01/01/09', '%d/%m/%y'), m.date_o
    assert_equal Date.strptime('01/01/09', '%d/%m/%y'), m.date_v
    assert_equal "FACTURA TARGETA CREDIT", m.txt1
    assert_equal Money.new(7721, Money::Currency.new(Setting.plugin_haltr['default_currency'])), m.amount
    
    m = @moviments.shift
    assert_equal Money.new(11791, Money::Currency.new(Setting.plugin_haltr['default_currency'])), m.amount
    assert_equal "B63456630", m.ref1        # tax id
    assert_equal "4660", m.ref2        # invoice number    
  end
  
end
