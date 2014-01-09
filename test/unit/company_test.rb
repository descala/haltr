require File.dirname(__FILE__) + '/../test_helper'

class CompanyTest < ActiveSupport::TestCase
  fixtures :clients, :companies

  test "public, semipublic and private accessors" do
    assert !companies(:company1).public?
    assert !companies(:company1).semipublic?
    assert companies(:company1).private?
    assert companies(:company2).public?
  end

  test "taxcode required in some countries" do
    c = Company.new(:name => "test_company_taxcode",
                    :project_id => 1,
                    :email => "email@example.com",
                    :postalcode => "08080",
                    :country => "is")
    assert c.valid?
    c.country = "es"
    assert !c.valid?
    c.taxcode = "B776655"
    assert c.valid?
  end
end
