require File.dirname(__FILE__) + '/../test_helper'

class BankInfoTest < ActiveSupport::TestCase
  fixtures :companies, :bank_infos

  test "user needs role to add more than one bank accounts" do
    assert_equal(1,companies(:company1).bank_infos.size)
    #TODO
  end

  test "iban requires bic" do
    bi3 = bank_infos(:bi3)
    assert_false bi3.valid?
    bi3.bic = "1"
    assert bi3.valid?
  end

end
