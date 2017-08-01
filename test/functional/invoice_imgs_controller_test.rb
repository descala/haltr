require File.expand_path('../../test_helper', __FILE__)

class InvoiceImgsControllerTest < ActionController::TestCase
  fixtures :companies, :invoices, :invoice_lines, :taxes

  def setup
    User.current = nil
    @request.session[:user_id] = 2
  end

  test "create" do
    post :create, format: 'json',
      "invoice_img"=>{
      invoice_id: 10, 
      json: File.read(File.dirname(__FILE__)+"/../../test/fixtures/documents/ostrich_out.json")}
    assert_response :success
    assert(Invoice.find(10).invoice_img.img, "asdf")
  end

end
