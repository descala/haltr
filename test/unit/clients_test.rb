require File.dirname(__FILE__) + '/../test_helper'

class ClientTest < ActiveSupport::TestCase

  fixtures :clients, :companies, :people, :bank_infos

  test 'client payment_method' do
    c = clients(:client1)
    assert_equal(Invoice::PAYMENT_CASH, c.payment_method)
    assert_nil c.bank_info_id
    assert_nil c.bank_info
    c.payment_method = "#{Invoice::PAYMENT_TRANSFER}_1"
    assert_equal(bank_infos(:bi1),c.bank_info)
    assert c.valid?
    c.payment_method = "#{Invoice::PAYMENT_TRANSFER}_2"
    assert !c.valid? # bank_info is from other company
    c.payment_method = Invoice::PAYMENT_TRANSFER
    assert c.valid?
    assert_nil c.bank_info
    c.payment_method = "#{Invoice::PAYMENT_DEBIT}_1"
    assert_equal(c.bank_info,bank_infos(:bi1))
    assert c.valid?
  end

  test 'client without iban or bank_account' do
    c = clients(:clients_001)
    assert c.valid?
    c.bank_account = ""
    assert c.valid?, "client is not valid (#{c.errors.full_messages.join(" / ")})"
  end

end
