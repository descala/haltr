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

end
