require File.dirname(__FILE__) + '/../test_helper'

class BankInfoTest < ActiveSupport::TestCase
  fixtures :companies,:bank_infos

  test "user needs role to add more than one bank accounts" do
    #TODO
  end

  test "valid IBAN" do
    assert BankInfo.new(:iban=>'ES0700120345030000067890').valid?
  end

  test "invalid IBAN is still valid (relax restriction on My Company)" do
    assert BankInfo.new(:iban=>'ES9900120345030000067890').valid?
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

  test "bank_account to IBAN conversion" do
    iban = BankInfo.local2iban('es','00120345030000067890')
    assert_equal 'ES0700120345030000067890', iban
    iban = BankInfo.local2iban(:es,'00120345030000067899')
    assert_equal 'ES5500120345030000067899', iban
  end

  test "IBAN to bank_account conversion" do
    ccc = BankInfo.iban2local('es','ES4020810000883300121217')
    assert_equal '20810000883300121217', ccc
    ccc = BankInfo.iban2local(:es,'ES5500120345030000067899')
    assert_equal "", ccc, "00120345030000067899 is not a valid spanish ccc"
  end

  test "spanish ccc" do
    assert BankInfo.valid_spanish_ccc?("20810000883300121217")
    assert !BankInfo.valid_spanish_ccc?("20810000883300121218")
    assert !BankInfo.valid_spanish_ccc?("2081000121")
    assert !BankInfo.valid_spanish_ccc?("208100asdf")
    assert !BankInfo.valid_spanish_ccc?("")
    assert !BankInfo.valid_spanish_ccc?(nil)
  end

end
