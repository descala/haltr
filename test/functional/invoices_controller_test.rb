require File.dirname(__FILE__) + '/../test_helper'

class InvoicesControllerTest < ActionController::TestCase
  fixtures :companies, :invoices, :invoice_lines, :taxes

  include Haltr::XmlValidation

  def setup
    User.current = nil
    @request.session[:user_id] = 2
  end

  test "must_redirect_if_not_configured" do
    # deconfigure onlinestore
    companies(:company1).destroy
    get :index, :id => 'onlinestore'
  end

  test 'facturae30' do
    get :show, :id => 4, :format => 'facturae30'
    assert_response :success
    xml = @response.body
    assert xml
    #TODO assert_equal [], facturae_errors_xsd(xml)
  end

  test 'facturae31' do
    get :show, :id => 4, :format => 'facturae31'
    assert_response :success
    xml = @response.body
    assert xml
    # TODO assert_equal [], facturae_errors_xsd(xml)
  end

  test 'facturae32' do
    Invoice.find(2).save!
    get :show, :id => 4, :format => 'facturae32'
    assert_response :success
    xml = @response.body
    assert xml
    assert_equal [], facturae_errors_xsd(xml)
  end

  test 'facturae_xml_i5_vat_excemption' do
    get :show, :id => 5, :format => 'facturae32'
    assert_response :success
    xml = @response.body
    assert_equal [], facturae_errors_online(xml)
  end

  test 'facturae_xml_i6_vat_and_charges' do
    get :show, :id => 6, :format => 'facturae32'
    assert_response :success
    xml = @response.body
    assert_equal [], facturae_errors_online(xml)
  end

  test 'facturae_xml_i7_vat_10_vat_20_and_charges' do
    get :show, :id => 7, :format => 'facturae32'
    assert_response :success
    xml = @response.body
    assert_equal [], facturae_errors_online(xml)
  end

  test 'biiubl20_xml_i4' do
    get :show, :id => 4, :format => 'biiubl20'
    assert_response :success
    xml = @response.body
    assert_equal [], ubl_errors(xml)
  end

  test 'biiubl20_xml_i5_vat_excemption' do
    get :show, :id => 5, :format => 'biiubl20'
    assert_response :success
    xml = @response.body
    assert_equal [], ubl_errors(xml)
  end

  test 'biiubl20_xml_i6_vat_and_charges' do
    get :show, :id => 6, :format => 'biiubl20'
    assert_response :success
    xml = @response.body
    assert_equal [], ubl_errors(xml)
  end

  test 'peppolubl20_xml_i7_vat_10_vat_20_and_charges' do
    get :show, :id => 7, :format => 'peppolubl20'
    assert_response :success
    xml = @response.body
    assert_equal [], ubl_errors(xml)
  end

  test 'facturae_xml_i8_vat_10_irpf_10_and_charges' do
    get :show, :id => 8, :format => 'facturae32'
    assert_response :success
    xml = @response.body
    assert_equal [], facturae_errors_online(xml)
  end

  test 'by_taxcode_and_num' do
    @request.session[:user_id] = nil
    get :by_taxcode_and_num, :num => "08/001", "taxcode"=>"77310058C"
    assert_response :success
    assert_equal "855445292", @response.body
    @request.session[:user_id] = 2
  end

  test 'import xml invoice' do
    post :import, {
      file:       fixture_file_upload('/documents/invoice_facturae32_issued.xml','text/xml'),
      commit:     'Importar',
      project_id: 'onlinestore',
      issued:     '1'
    }
    p=Project.find(2)
    assert User.current.allowed_to?(:import_invoices,p), "user #{User.current.login} has not import_invoices permission in project #{p.name}"
    assert_response :found
    assert invoice = IssuedInvoice.find_by_number('767'), "should find imported invoice"
    assert invoice.valid?, invoice.errors.messages.to_s
    assert !invoice.modified_since_created?
    assert invoice.original
  end

  test 'import pdf invoice' do

    stub_request(:post, "http://localhost:3000/api/v1/transactions")
    .to_return(:status => 200,
               :body => "",
               :headers => {})

    post :import, {
      file:       fixture_file_upload('/documents/invoice_pdf_signed.pdf','application/pdf'),
      commit:     'Importar',
      project_id: 'onlinestore',
      issued:     '1'
    }
    p=Project.find(2)
    assert User.current.allowed_to?(:import_invoices,p), "user #{User.current.login} has not import_invoices permission in project #{p.name}"
    assert_response :found
    assert invoice = IssuedInvoice.last
    assert !invoice.valid?
    assert_equal "processing_pdf", invoice.state
    assert !invoice.modified_since_created?
    assert invoice.original
  end

  test 'create invoice without client when there are no clients' do
    post :create, {
      project_id: 'onlinestore',
      invoice: {}
    }
    assert_response :success
  end

end
