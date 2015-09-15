require File.dirname(__FILE__) + '/../test_helper'

class HaltrUtilsTest < ActiveSupport::TestCase

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

end

