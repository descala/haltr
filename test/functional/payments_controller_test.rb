require File.dirname(__FILE__) + '/../test_helper'

class PaymentsControllerTest < ActionController::TestCase

  fixtures :invoices, :bank_infos, :companies, :clients

  def setup
    @due = invoices(:invoice1).due_date
    @venci = @due.to_formatted_s :ddmmyy
  end

  test "generates SEPA XML" do
    @request.session[:user_id] = 2
    get "sepa", :project_id => 2, :due_date => @due, :bank_info => 1, :invoices => [invoices(:invoice1).id], :sepa_type => 'CORE'
    assert_response :success
    assert_equal 'text/xml', @response.content_type
    xml = Nokogiri::XML(@response.body)
    xml.remove_namespaces!
    assert_equal invoices(:invoice1).client_iban, xml.xpath('//DbtrAcct/Id/IBAN').text
    assert_equal invoices(:invoice1).bank_info.iban, xml.xpath('//CdtrAcct/Id/IBAN').text
    assert_equal "08/194 08/001", xml.xpath('//EndToEndId').text
    assert_equal "Invoice 08/194 08/001", xml.xpath('//Ustrd').text
    assert_equal "1851.36", xml.xpath('//InstdAmt').text
  end

  def test_aeb43
    @request.session[:user_id] = 2
    get "import_aeb43_index", :project_id => 2 
    assert_response :success
    #TODO post "import_aeb43"
  end

end
