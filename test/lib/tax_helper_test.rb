require File.dirname(__FILE__) + '/../test_helper'

class TaxHelperTest < ActiveSupport::TestCase

  fixtures :taxes, :companies

  # Si només hi ha un impost, posar S.
  # Si un impost és 0, posar-li Z
  # Si n'hi ha dos (i no és 0) posar S a l'alt i AA al baix
  # Si n'hi ha tres, posar S al del mig, AA al baix i H a l'alt.

  include Haltr::TaxHelper

  test "category_S" do
    company = companies(:company1)
    company.taxes = []
    company.taxes <<  Tax.new(:name=>'test',:percent=>10.0)
    company.save!
    guess_tax_category company
    company.reload
    t1 = company.taxes.first
    assert_equal 'S', t1.category
  end

  test "category_Z" do
    company = companies(:company1)
    company.taxes = []
    company.taxes << Tax.new(:name=>'test',:percent=>0.0)
    company.save!
    guess_tax_category company
    company.reload
    t1 = company.taxes.first
    assert_equal 'Z', t1.category
  end

  test "category_S_and_AA" do
    company = companies(:company1)
    company.taxes = []
    company.taxes << Tax.new(:name=>'VAT',:percent=>2.0)
    company.taxes << Tax.new(:name=>'VAT',:percent=>5.0)
    company.save!
    guess_tax_category company
    company.reload
    taxes = company.taxes.sort
    assert_equal 'AA', taxes[0].category
    assert_equal 'S', taxes[1].category
  end

  test "category_all" do
    company = companies(:company1)
    company.taxes = []
    company.taxes << Tax.new(:name=>'IRPF',:percent=>0.0)
    company.taxes << Tax.new(:name=>'IRPF',:percent=>-15.0)
    company.taxes << Tax.new(:name=>'VAT',:percent=>0.0)
    company.taxes << Tax.new(:name=>'VAT',:percent=>2.0)
    company.taxes << Tax.new(:name=>'VAT',:percent=>5.0)
    company.taxes << Tax.new(:name=>'VAT',:percent=>6.0)
    company.save!
    guess_tax_category company
    company.reload
    taxes = company.taxes.sort
    assert_equal 'Z',  taxes[0].category
    assert_equal 'S',  taxes[1].category
    assert_equal 'Z',  taxes[2].category
    assert_equal 'AA', taxes[3].category
    assert_equal 'S',  taxes[4].category
    assert_equal 'H',  taxes[5].category
  end

end
