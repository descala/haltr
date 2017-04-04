require File.expand_path('../../test_helper', __FILE__)

class CompanyTest < ActiveSupport::TestCase
  fixtures :clients, :companies

  test "public, semipublic and private accessors" do
    assert !companies(:company1).public?
    assert !companies(:company1).semipublic?
    assert companies(:company1).private?
    assert companies(:company2).public?
  end

  test "taxcode required in some countries" do
    c = Company.new(:name => "test_company_taxcode",
                    :project_id => 1,
                    :email => "email@example.com",
                    :postalcode => "08080",
                    :country => "is",
                    :rounding_method => 'half_up')
    assert c.valid?, c.errors.full_messages.join(' ')
    c.country = "es"
    assert !c.valid?
    c.taxcode = "ESX4942978W"
    assert c.valid?
  end

  #TODO: test cifs with dashes, spaces...
  test 'sepa_creditor_identifier generated correctly' do
    assert_equal "ES73000B63354724", companies(:company3).sepa_creditor_identifier
    assert_equal "ES0200077310058C", companies(:company1).sepa_creditor_identifier
    assert_equal "ES42000A28022143", companies(:company2).sepa_creditor_identifier
  end

  test 'works when xxx_mail_customization is not a Hash' do
    c = companies('company1')
    c.invoice_mail_customization = ''
    c.invoice_mail_subject_es = 'Subject'
    c.invoice_mail_customization = ''
    c.invoice_mail_body_es = 'Body'
    c.quote_mail_customization = ''
    c.quote_mail_subject_es = 'Subject'
    c.quote_mail_customization = ''
    c.quote_mail_body_es = 'Body'
  end

  test 'email customization' do
    c = companies('company1')
    assert_equal "Invoice number @invoice.number", c.invoice_mail_subject_en
    c.invoice_mail_subject_en = "Yayh"
    assert_equal "Yayh", c.invoice_mail_subject_en
    c.invoice_mail_body_en = "Yayh"
    assert_equal "Yayh", c.invoice_mail_body_en
  end

  test 'company last_name never is blank' do
    assert_equal '.', companies('company1').last_name
  end

end
