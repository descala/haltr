require File.dirname(__FILE__) + '/../test_helper'

class UtilsTest < ActiveSupport::TestCase

  test 'to_money' do
    assert_equal 300,  Haltr::Utils.to_money(3).cents
    assert_equal 300,  Haltr::Utils.to_money('3').cents
    assert_equal 350,  Haltr::Utils.to_money(3.5).cents
    assert_equal 350,  Haltr::Utils.to_money('3.5').cents
    assert_equal 350,  Haltr::Utils.to_money('3,5').cents
    assert_equal 5764, Haltr::Utils.to_money('57.64').cents
    # half up rounding
    assert_equal 0,    Haltr::Utils.to_money('0.004',nil,:half_up).cents
    assert_equal 1,    Haltr::Utils.to_money('0.005',nil,:half_up).cents
    assert_equal 1,    Haltr::Utils.to_money('0.006',nil,:half_up).cents
    assert_equal 2,    Haltr::Utils.to_money('0.015',nil,:half_up).cents
    # banker's rounding
    assert_equal 0,    Haltr::Utils.to_money('0.004',nil,:bankers).cents
    assert_equal 0,    Haltr::Utils.to_money('0.005',nil,:bankers).cents
    assert_equal 1,    Haltr::Utils.to_money('0.006',nil,:bankers).cents
    assert_equal 2,    Haltr::Utils.to_money('0.015',nil,:bankers).cents
    assert_equal 2,    Haltr::Utils.to_money('0.025',nil,:bankers).cents
    # truncate rounding
    assert_equal 0,    Haltr::Utils.to_money('0.005',nil,:truncate).cents
    assert_equal 0,    Haltr::Utils.to_money('0.006',nil,:truncate).cents
    assert_equal 1,    Haltr::Utils.to_money('0.015',nil,:truncate).cents
    assert_equal 1,    Haltr::Utils.to_money('0.019',nil,:truncate).cents
  end

  test 'sbdh extract' do
    file = File.new(File.join(File.dirname(__FILE__),'../fixtures/documents/invoice_ubl_with_sbdh.xml'))
    doc = Nokogiri::XML(file)
    invoice = Haltr::Utils.extract_from_sbdh(doc)
    assert_equal '0070075', invoice.xpath("/xmlns:Invoice/cbc:ID").text
  end

  test 'removes leading and trailing spaces' do
    xml = "<xml><withspaces>  a test    </withspaces></xml>"
    doc = Nokogiri::XML(xml)
    assert_equal 'a test', Haltr::Utils.get_xpath(doc,'//withspaces')
  end
end

