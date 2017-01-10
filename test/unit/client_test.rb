require File.expand_path('../../test_helper', __FILE__)

class ClientTest < ActiveSupport::TestCase

  fixtures :clients, :companies, :people, :bank_infos, :invoices

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

  test 'bank_invoices_ methods' do
    due_date = Date.new(2014,02,01)
    c = clients(:client1)
    assert_equal 4, c.invoices.size
    c.issued_invoices.each do |i|
      i.due_date       = due_date
      i.payment_method = Invoice::PAYMENT_DEBIT
      i.bank_info      = bank_infos(:bi1)
      i.terms          = 'custom'
      i.state          = 'sent'
      assert i.save
    end
    assert_equal 2, c.bank_invoices(due_date,bank_infos(:bi1).id).size
    total = c.issued_invoices.collect {|i| i.import }.sum
    assert_equal total, c.bank_invoices_total(due_date, bank_infos(:bi1).id)
    i = c.issued_invoices.last
    i.bank_info = bank_infos(:bi4)
    i.save
    assert_equal 1, c.bank_invoices(due_date,bank_infos(:bi1).id).size
    assert_equal c.issued_invoices.first.total, c.bank_invoices_total(due_date, bank_infos(:bi1))
    assert_equal 1, c.bank_invoices(due_date,bank_infos(:bi4).id).size
    assert_equal c.issued_invoices.first.total, c.bank_invoices_total(due_date, bank_infos(:bi1))
  end

  test 'client without iban or bank_account' do
    c = clients(:clients_001)
    assert c.valid?
    c.bank_account = ""
    assert c.valid?, "client is not valid (#{c.errors.full_messages.join(" / ")})"
  end

end
