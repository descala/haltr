require File.dirname(__FILE__) + '/../test_helper'

class BankInfoTest < ActiveSupport::TestCase
  fixtures :companies, :bank_infos

  test "user needs role to add more than one bank accounts" do
    assert_equal(1,companies(:company1).bank_infos.size)
    #TODO
  end

  test "iban requires bic" do
    bi3 = bank_infos(:bi3)
    assert !bi3.valid?
    bi3.bic = "12345678"
    assert bi3.valid?
  end

  test "bic too long" do
    bi3 = bank_infos(:bi3)
    bi3.bic = "123456789012"
    assert !bi3.valid?
  end

  test "bic allow nil and blank" do
    bi3 = bank_infos(:bi3)
    bi3.iban = ""
    bi3.bic = ""
    assert bi3.valid?
    bi3.bic = nil
    bi3.bic = nil
    assert bi3.valid?
  end

end
