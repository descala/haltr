require File.expand_path('../../test_helper', __FILE__)

class InvoiceLineTest < ActiveSupport::TestCase
  fixtures :clients, :invoices, :invoice_lines, :taxes, :companies, :people,
    :bank_infos, :dir3_entities, :external_companies, :client_offices

  test "invoice lines with RE taxes need an IVA tax with the same category" do
    il = InvoiceLine.new(quantity: 1, price: 1)
    assert(il.valid?)
    il.taxes << Tax.new(name: 'RE', category: 'S', percent: 5.2)
    assert_equal(1, il.taxes.size)
    assert(!il.valid?, 'Line with RE tax but no IVA should be invalid')
    il.taxes << Tax.new(name: 'IVA', category: 'AA', percent: 10)
    assert(!il.valid?, 'Line with RE tax but no IVA with the same category should be invalid')
    il.taxes << Tax.new(name: 'IVA', category: 'S', percent: 21)
    assert(il.valid?, 'Line with RE tax and IVA with the same category should be valid')
  end

  test "invoice lines with negative quantity and discount amount" do
    il = InvoiceLine.new(quantity: -1, price: 10, discount_amount: 1)
    assert(il.valid?, il.errors.full_messages)
    assert_equal(-1, il.discount.to_f)
    assert_equal(-9, il.taxable_base.to_f)
  end

  test "invoice lines with negative quantity and discount percent" do
    il = InvoiceLine.new(quantity: -1, price: 10, discount_percent: 10)
    assert(il.valid?, il.errors.full_messages)
    assert_equal(-1, il.discount_amount.to_f)
    assert_equal(-9, il.taxable_base.to_f)
  end

  test "invoice lines with discount percent" do
    il = InvoiceLine.new(quantity: 1, price: 10, discount_percent: 10)
    assert(il.valid?, il.errors.full_messages)
    assert_equal 1, il.discount_amount.to_f
    assert_equal(9, il.taxable_base.to_f)
  end

  test "invoice lines with negative discount are invalid" do
    il = InvoiceLine.new(quantity: 1, price: 10, discount_percent: -10)
    assert(il.valid?)
    assert_equal 10, il.discount_percent
    il = InvoiceLine.new(quantity: 1, price: 10, discount_amount: -1)
    assert(il.valid?)
    assert_equal 1, il.discount_amount
  end

end
