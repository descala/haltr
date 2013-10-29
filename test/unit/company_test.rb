require File.dirname(__FILE__) + '/../test_helper'

class CompanyTest < ActiveSupport::TestCase
  fixtures :clients, :companies

  test "public, semipublic and private accessors" do
    assert_false companies(:company1).public?
    assert_false companies(:company1).semipublic?
    assert_true  companies(:company1).private?
    assert_true  companies(:company2).public?
  end

  test "taxcode required in some countries" do
    c = Company.new(:name => "test_company_taxcode",
                    :project_id => 1,
                    :email => "email@example.com",
                    :postalcode => "08080",
                    :country => "is")
    assert_true c.valid?
    c.country = "es"
    assert_false c.valid?
    c.taxcode = "B776655"
    assert_true c.valid?
  end
end
