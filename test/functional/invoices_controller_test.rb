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

  test 'by_taxcode_and_num with date' do
    @request.session[:user_id] = nil
    get :by_taxcode_and_num, :num => "08/001", "taxcode"=>"77310058C", "date"=>"2008-11-24"
    assert_response :success
    assert_equal "855445292", @response.body
    get :by_taxcode_and_num, :num => "08/001", "taxcode"=>"77310058C", "date"=>"1111-11-11"
    assert_response :not_found
    @request.session[:user_id] = 2
  end

  test 'by_taxcode_and_num with serie' do
    @request.session[:user_id] = nil
    get :by_taxcode_and_num, :num => "08/001", "taxcode"=>"77310058C", "serie"=>"15"
    assert_response :success
    assert_equal "855445292", @response.body
    get :by_taxcode_and_num, :num => "08/001", "taxcode"=>"77310058C", "serie"=>"11"
    assert_response :not_found
    @request.session[:user_id] = 2
  end

  test 'import invoice with multiple upload' do
    set_tmp_attachments_directory
    attachment = Attachment.create!(:file => fixture_file_upload('/documents/invoice_facturae32_issued.xml','text/xml',true), :author_id => 2)

    post :upload, {
      attachments: {'p0' => {'token' => attachment.token}},
      commit:     'Importar',
      project_id: 'onlinestore',
      issued:     'true'
    }
    p=Project.find(2)
    assert User.current.allowed_to?(:import_invoices,p), "user #{User.current.login} has not import_invoices permission in project #{p.name}"
    assert_response :found
    assert invoice = IssuedInvoice.find_by_number('767'), "should find imported invoice"
    assert invoice.valid?, invoice.errors.messages.to_s
    assert !invoice.modified_since_created?
    assert invoice.original
  end

  test 'import pdf invoice with multiple upload' do

    stub_request(:post, "http://localhost:3000/api/v1/transactions")
    .to_return(:status => 200,
               :body => "",
               :headers => {})

    set_tmp_attachments_directory
    attachment = Attachment.create!(:file => fixture_file_upload('/documents/invoice_pdf_signed.pdf','application/pdf',true), :author_id => 2)

    post :upload, {
      attachments: {'p0' => {'token' => attachment.token}},
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

  test 'edit sent invoice sets state to new' do
    i = invoices(:invoices_002)
    i = Invoice.find i.id
    assert_equal 'sent', i.state
    assert_equal 100.3, i.total.dollars
    assert_equal 15, i.discount_percent
    lines = i.invoice_lines.collect {|l| l.attributes }
    new_line = {
      quantity: 1,
      description: 'new',
      price: 10,
      taxes_attributes: [{
        name: 'IVA',
        percent: 0,
        category: 'E'
      }]
    }
    lines << new_line
    put :update, id: i, invoice: {
      invoice_lines_attributes: lines
    }
    i.reload
    # editing a sent invoice should set state to new
    assert_equal 'new', i.state
    # it should update imports too, despite only invoice_lines changed
    assert_equal 108.8, i.total.dollars
  end

end
