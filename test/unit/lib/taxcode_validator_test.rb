require File.expand_path('../../../test_helper', __FILE__)

class TaxcodeValidatorTest < ActiveSupport::TestCase

  test "es clients require taxcode" do
    client = Client.new(
      country: 'es',
      name: 'test',
      language: 'es',
      project_id: 1,
      company_identifier: '123'
    )
    assert !client.valid?
    assert_equal 'VAT ID Number cannot be blank', client.errors.full_messages.join
    client.taxcode = 'AAAAAAAAAAA'
    assert !client.valid?
    assert_equal 'VAT ID Number is not a valid Spanish vat number', client.errors.full_messages.join
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
    assert_equal 'VAT ID Number cannot be blank', client.errors.full_messages.join(' ')
    client.taxcode = '123456789'
    assert client.valid?, client.errors.full_messages.join(' ')
    client.taxcode = ''
    assert !client.valid?
    client.company_identifier = '1234'
    assert client.valid?, client.errors.full_messages.join(' ')
  end

  test 'fr clients require taxcode or company_identifier' do
    client = Client.new(
      country: 'fr',
      name: 'test',
      language: 'en',
      project_id: 1
    )
    assert !client.valid?
    assert_equal 'VAT ID Number cannot be blank', client.errors.full_messages.join(' ')
    client.taxcode = 'FR60528551658'
    assert client.valid?, client.errors.full_messages.join(' ')
    client.taxcode = ''
    assert !client.valid?
    client.company_identifier = '1234'
    assert client.valid?, client.errors.full_messages.join(' ')
  end

end
