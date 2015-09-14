require File.dirname(__FILE__) + '/../test_helper'

class TaxHelperTest < ActiveSupport::TestCase

  fixtures :taxes, :companies

  # Si només hi ha un impost, posar S.
  # Si un impost és 0, posar-li Z
  # Si n'hi ha dos (i no és 0) posar S a l'alt i AA al baix
  # Si n'hi ha mes de dos, posar S a l'alt, i AA a la resta.

  include Haltr::TaxHelper

  test "category_S" do
    company = companies(:company1)
    company.taxes = []
    company.taxes <<  Tax.new(:name=>'test',:percent=>10.0)
    company.taxes = guess_tax_category(company.taxes)
    company.save!
    t1 = company.taxes.first
    assert_equal 'S', t1.category
  end

  test "category_Z" do
    company = companies(:company1)
    company.taxes = []
    company.taxes << Tax.new(:name=>'test',:percent=>0.0)
    company.taxes = guess_tax_category(company.taxes)
    company.save!
    t1 = company.taxes.first
    assert_equal 'Z', t1.category
  end

  test "category_S_and_AA" do
    company = companies(:company1)
    company.taxes = []
    company.taxes << Tax.new(:name=>'VAT',:percent=>2.0)
    company.taxes << Tax.new(:name=>'VAT',:percent=>5.0)
    company.taxes = guess_tax_category(company.taxes)
    company.save!
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
    company.taxes << Tax.new(:name=>'VAT',:percent=>7.0)
    company.taxes = guess_tax_category(company.taxes)
    company.save!
    taxes = company.taxes.sort
    assert_equal 'Z',  taxes[0].category
    assert_equal 'S',  taxes[1].category
    assert_equal 'Z',  taxes[2].category
    assert_equal 'AA', taxes[3].category
    assert_equal 'AA', taxes[4].category
    assert_equal 'AA', taxes[5].category
    assert_equal 'S',  taxes[6].category
  end

  test "default taxes" do
    default_taxes = default_taxes_for("es")
    assert_equal 7, default_taxes.size
    taxes = {}
    default_taxes.each do |tax|
      taxes[tax.name] ||= []
      taxes[tax.name] << tax
    end
    assert_equal 5, taxes["IVA"].size
    assert_equal "E",  taxes["IVA"].sort[0].category
    assert_equal 0,    taxes["IVA"].sort[0].percent
    assert_equal "Z",  taxes["IVA"].sort[1].category
    assert_equal 0,    taxes["IVA"].sort[1].percent
    assert_equal "AA", taxes["IVA"].sort[2].category
    assert_equal 4,    taxes["IVA"].sort[2].percent
    assert_equal "AA", taxes["IVA"].sort[3].category
    assert_equal 10,   taxes["IVA"].sort[3].percent
    assert_equal "S",  taxes["IVA"].sort[4].category
    assert_equal 21,   taxes["IVA"].sort[4].percent
    assert             taxes["IVA"].sort[4].default
    assert_equal 2, taxes["IRPF"].size
    assert_equal "S", taxes["IRPF"].first.category
  end

end
