require File.dirname(__FILE__) + '/../test_helper'

class FloatParserTest < ActiveSupport::TestCase

  test 'parses floats' do
    f = Invoice.new
    f.discount_percent = 12      ; assert_equal 12,   f.discount_percent
    f.discount_percent = '123'   ; assert_equal 123,  f.discount_percent
    f.discount_percent = '1.23'  ; assert_equal 1.23, f.discount_percent
    f.discount_percent = '1,23'  ; assert_equal 1.23, f.discount_percent
    f.discount_percent = '1,2.3' ; assert_equal 12.3, f.discount_percent
    f.discount_percent = '1.2,3' ; assert_equal 12.3, f.discount_percent
    f.discount_percent = '.123'  ; assert_equal 0,    f.discount_percent
    f.discount_percent = 'asd'   ; assert_equal 0,    f.discount_percent
    f.discount_percent = ''      ; assert_equal 0,    f.discount_percent
    f.discount_percent = nil     ; assert_equal 0,    f.discount_percent
    f.discount_percent = '123,'  ; assert_equal 0,    f.discount_percent
    f.discount_percent = '123a'  ; assert_equal 0,    f.discount_percent
    f.discount_percent = 'a123'  ; assert_equal 0,    f.discount_percent
    f.discount_percent = 12.300  ; assert_equal 12.3, f.discount_percent
    f.discount_percent = '12.3 ' ; assert_equal 12.3, f.discount_percent
    f.discount_percent = ' 12.3' ; assert_equal 12.3, f.discount_percent
    f.discount_percent = ' 1.3 ' ; assert_equal 1.3,  f.discount_percent
    f.discount_percent = -12      ; assert_equal(-12,   f.discount_percent)
    f.discount_percent = '-123'   ; assert_equal(-123,  f.discount_percent)
    f.discount_percent = '-1.23'  ; assert_equal(-1.23, f.discount_percent)
    f.discount_percent = '-1,23'  ; assert_equal(-1.23, f.discount_percent)
    f.discount_percent = '-1,2.3' ; assert_equal(-12.3, f.discount_percent)
    f.discount_percent = '-1.2,3' ; assert_equal(-12.3, f.discount_percent)
    f.discount_percent = '.-123'  ; assert_equal(0,    f.discount_percent)
    f.discount_percent = '-123,'  ; assert_equal(0,    f.discount_percent)
    f.discount_percent = '-123a'  ; assert_equal(0,    f.discount_percent)
    f.discount_percent = 'a-123'  ; assert_equal(0,    f.discount_percent)
    f.discount_percent = -12.300  ; assert_equal(-12.3, f.discount_percent)
    f.discount_percent = '-12.3 ' ; assert_equal(-12.3, f.discount_percent)
    f.discount_percent = ' -12.3' ; assert_equal(-12.3, f.discount_percent)
    f.discount_percent = ' -1.3 ' ; assert_equal(-1.3,  f.discount_percent)
    f.discount_percent = "1'3"    ; assert_equal(1.3,   f.discount_percent)
    f.discount_percent = "-1'3"   ; assert_equal(-1.3,  f.discount_percent)
    f.discount_percent = "1.001'3" ; assert_equal(1001.3, f.discount_percent)
    f.discount_percent = "1,001'3" ; assert_equal(1001.3, f.discount_percent)
  end

end

