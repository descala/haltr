require File.dirname(__FILE__) + '/../test_helper'

class TaxcodeValidatorTest < ActiveSupport::TestCase

  test "es clients require taxcode" do
    client = Client.new(
      country: 'es',
      name: 'test',
      language: 'es',
      project_id: 1
    )
    assert !client.valid?
    assert_equal 'VAT Id Number is not a valid Spanish vat number', client.errors.full_messages.join
    client.taxcode = 'ESP1700000A'
    assert client.valid?, client.errors.full_messages.join(' ')
  end

  test 'gb clients require taxcode or company_identifier' do
    client = Client.new(
      country: 'gb',
      name: 'test',
      language: 'en',
      project_id: 1
    )
    assert !client.valid?
    assert_equal 'Organization ID/Company Registration Number cannot be blank', client.errors.full_messages.join(' ')
    client.taxcode = '123456789'
    assert client.valid?, client.errors.full_messages.join(' ')
    client.taxcode = ''
    assert !client.valid?
    client.company_identifier = '1234'
    assert client.valid?
  end

  test 'fr clients require taxcode or company_identifier' do
    client = Client.new(
      country: 'fr',
      name: 'test',
      language: 'en',
      project_id: 1
    )
    assert !client.valid?
    assert_equal 'Organization ID/Company Registration Number cannot be blank', client.errors.full_messages.join(' ')
    client.taxcode = '12345678901'
    assert client.valid?, client.errors.full_messages.join(' ')
    client.taxcode = ''
    assert !client.valid?
    client.company_identifier = '1234'
    assert client.valid?
  end

end
