require File.dirname(__FILE__) + '/../test_helper'

class HaltrUtilsTest < ActiveSupport::TestCase

  test 'to_money' do
    assert_equal 300,  Haltr::Utils.to_money(3).cents
    assert_equal 300,  Haltr::Utils.to_money('3').cents
    assert_equal 350,  Haltr::Utils.to_money(3.5).cents
    assert_equal 350,  Haltr::Utils.to_money('3.5').cents
    assert_equal 350,  Haltr::Utils.to_money('3,5').cents
    assert_equal 5764, Haltr::Utils.to_money('57.64').cents
    # banker's rounding
    assert_equal 0,    Haltr::Utils.to_money('0.005').cents
    assert_equal 1,    Haltr::Utils.to_money('0.006').cents
    assert_equal 2,    Haltr::Utils.to_money('0.015').cents
  end

end

