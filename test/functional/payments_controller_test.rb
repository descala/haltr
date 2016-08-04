require File.expand_path('../../test_helper', __FILE__)

class PaymentsControllerTest < ActionController::TestCase

  fixtures :invoices, :bank_infos, :companies, :clients

  def setup
    @due = invoices(:invoice1).due_date
    @venci = @due.to_formatted_s :ddmmyy
    User.current = nil
    @request.session[:user_id] = 2
  end

  test "generates SEPA XML" do
    @request.session[:user_id] = 2
    get "sepa", :project_id => 2, :due_date => @due, :bank_info => 1, :invoices => [invoices(:invoice1).id], :sepa_type => 'CORE'
    assert_response :success
    assert_equal 'text/xml', @response.content_type
    xml = Nokogiri::XML(@response.body)
    xml.remove_namespaces!
    assert_equal invoices(:invoice1).client.iban, xml.xpath('//DbtrAcct/Id/IBAN').text
    assert_equal invoices(:invoice1).bank_info.iban, xml.xpath('//CdtrAcct/Id/IBAN').text
    assert_equal "08/194 08/001", xml.xpath('//EndToEndId').text
    assert_equal "Invoice 08/194 08/001", xml.xpath('//Ustrd').text
    assert_equal "1851.36", xml.xpath('//InstdAmt').text
  end

  test 'create payment' do
    post :create, {
      project_id: 'onlinestore',
      payment: {
        invoice_id: invoices(:invoices_002).id,
        amount: '10',
        date: '2015-08-04',
        payment_method: '',
        reference: ''
      }
    }
    assert_redirected_to controller: 'payments', action: 'index'
  end

  test 'cannot create payment to invoice on other project' do
    # there's no invoice_003 on onlinestore project
    assert_raise ActiveRecord::RecordNotFound do
      post :create, {
        project_id: 'onlinestore',
        payment: {
          invoice_id: invoices(:invoices_003).id,
          amount: '10',
          date: '2015-08-04',
          payment_method: '',
          reference: ''
        }
      }
    end
  end

  def test_aeb43
    @request.session[:user_id] = 2
    get "import_aeb43_index", :project_id => 2 
    assert_response :success
    #TODO post "import_aeb43"
  end

end
