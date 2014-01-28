require File.dirname(__FILE__) + '/../test_helper'

class PaymentsControllerTest < ActionController::TestCase

  fixtures :invoices, :bank_infos, :companies

  def setup
    @due = invoices(:invoice1).due_date
    @venci = @due.to_formatted_s :ddmmyy
  end

  def test_n19
    Haltr::TestHelper.fix_invoice_totals
    @request.session[:user_id] = 2
    get "n19", :project_id => 2, :due_date => @due, :bank_info => 1, :invoices => [invoices(:invoice1).id]
    assert_response :success
    assert_template 'payments/n19'
    assert_not_nil assigns(:due_date)
    assert_equal 'text/plain', @response.content_type
    lines = @response.body.chomp.split("\n")
    fecha_confeccion = Date.today.to_formatted_s :ddmmyy
    # spaces are relevant
    assert_equal "518077310058H000#{fecha_confeccion}      COMPANY1                                                    12345678                                                                  ", lines[0]
    assert_equal "538077310058H000#{fecha_confeccion}#{@venci}Company1                                12345678901234567890        01                                                                ", lines[1]
    assert_equal "568077310058H000B00000000   SOME NON'ASCII CHARS ?? LONG NAME THAT M114910865126953221150000092568                FRA 08/001                        925,68        ", lines[2]
  end

  def test_n19_with_eur_nif
    c = companies(:company1)
    c.taxcode = "ES77310000G"
    c.save
    Haltr::TestHelper.fix_invoice_totals
    @request.session[:user_id] = 2
    get "n19", :project_id => 2, :due_date => @due, :bank_info => 1, :invoices => [invoices(:invoice1).id]
    assert_response :success
    assert_template 'payments/n19'
    assert_not_nil assigns(:due_date)
    assert_equal 'text/plain', @response.content_type
    lines = @response.body.chomp.split("\n")
    fecha_confeccion = Date.today.to_formatted_s :ddmmyy
    # spaces are relevant
    assert_equal "518077310000G000#{fecha_confeccion}      COMPANY1                                                    12345678                                                                  ", lines[0]
    assert_equal "538077310000G000#{fecha_confeccion}#{@venci}Company1                                12345678901234567890        01                                                                ", lines[1]
    assert_equal "568077310000G000B00000000   SOME NON'ASCII CHARS ?? LONG NAME THAT M114910865126953221150000092568                FRA 08/001                        925,68        ", lines[2]
  end

  test "generates SEPA XML" do
    @request.session[:user_id] = 2
    get "sepa", :project_id => 2, :due_date => @due, :bank_info => 1, :invoices => [invoices(:invoice1).id], :sepa_type => 'CORE'
    assert_response :success
    assert_equal 'text/xml', @response.content_type
    xml=@response.body
    assert xml.include?('Invoice 08/194 08/001')
    assert xml.include?('ES8023100001180000012345</IBAN>')
    assert xml.include?('1851.36</InstdAmt>')
  end

  def test_aeb43
    @request.session[:user_id] = 2
    get "import_aeb43_index", :project_id => 2 
    assert_response :success
    #TODO post "import_aeb43"
  end

end
