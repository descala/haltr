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

  #TODO: test cifs with dashes, spaces...
  test 'sepa_creditor_identifier generated correctly' do
    assert_equal "ES73000B63354724", companies(:company3).sepa_creditor_identifier
    assert_equal "ES77000B85626240", companies(:company4).sepa_creditor_identifier
    assert_equal "ES6100077310058H", companies(:company1).sepa_creditor_identifier
    assert_equal "ES80000S2802214E", companies(:company2).sepa_creditor_identifier
    assert_equal "ES0200077310058C", companies(:company5).sepa_creditor_identifier
  end
end
