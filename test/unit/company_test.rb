require File.dirname(__FILE__) + '/../test_helper'

class CompanyTest < ActiveSupport::TestCase
  fixtures :clients, :companies

  test "public, semipublic and private accessors" do
    assert_false companies(:company1).public?
    assert_false companies(:company1).semipublic?
    assert_true  companies(:company1).private?
    assert_true  companies(:company2).public?
  end
end
