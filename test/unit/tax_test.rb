require File.dirname(__FILE__) + '/../test_helper'

class TaxTest < ActiveSupport::TestCase

  test "tax_code_getter" do
    t = Tax.new
    assert_equal "S", t.category
    assert_equal "S", t.code
    t.percent = 8.0
    assert_equal "8.0_S", t.code
    t.code = ""
  end

  test "tax_code_setter" do
    t = Tax.new
    t.code = "21.0_S"
    assert_equal 21.0, t.percent
    assert_equal "S", t.category
    t = Tax.new
    t.code = ""
    assert_nil t.percent
    assert_nil t.category
  end

end
