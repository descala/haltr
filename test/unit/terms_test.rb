require File.expand_path('../../test_helper', __FILE__)

class TermsTest < ActiveSupport::TestCase
  def test_due_dates
    date = Date.new(2000,8,10)

    terms = Terms.new(nil,date)
    assert_equal date, terms.due_date 

    terms = Terms.new(0,date)
    assert_equal date, terms.due_date
    
    terms = Terms.new(15,date)
    assert_equal Date.new(2000,8,25), terms.due_date
    
    terms = Terms.new("1m20",date)
    assert_equal Date.new(2000,9,20), terms.due_date
    
    date = Date.new(2000,12,10)
    terms = Terms.new("1m20",date)
    assert_equal Date.new(2001,1,20), terms.due_date
  
  end
end
