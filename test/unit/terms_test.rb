require 'test_helper'

class TermsTest < ActiveSupport::TestCase
  def test_descriptions
    date = Date.new(2000,8,10)

    terms = Terms.new(nil,date)
    assert_equal Terms::NOW, terms.description
    assert_equal date, terms.due_date 

    terms = Terms.new(0,date)
    assert_equal Terms::NOW, terms.description
    assert_equal date, terms.due_date
    
    terms = Terms.new(15,date)
    assert_equal sprintf(Terms::DAYS,15), terms.description
    assert_equal Date.new(2000,8,25), terms.due_date
    
    terms = Terms.new("1m20",date)
    assert_equal sprintf(Terms::DAYNM,20), terms.description
    assert_equal Date.new(2000,9,20), terms.due_date
    
    date = Date.new(2000,12,10)
    terms = Terms.new("1m20",date)
    assert_equal sprintf(Terms::DAYNM,20), terms.description
    assert_equal Date.new(2001,1,20), terms.due_date
  
  end
end
