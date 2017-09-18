require File.expand_path('../../test_helper', __FILE__)

class InvoiceTemplatesControllerTest < ActionController::TestCase
  fixtures :companies, :invoices, :invoice_lines, :taxes

  include Haltr::XmlValidation

  def setup
    User.current = nil
    @request.session[:user_id] = 2
  end

  test "generated invoice has same taxes as template" do
    draft_count = DraftInvoice.count

    # 1) generate DraftInvoice
    get :new_invoices_from_template, :project_id => 'onlinestore'
    assert_response :success
    assert_equal draft_count+1, DraftInvoice.count
    draft = DraftInvoice.last
    assert_nil draft.number
    assert_equal invoices(:template1).invoice_lines.first.taxes.first, draft.invoice_lines.first.taxes.first

    # 2) generate IssuedInvoice from DraftInvoice + number
    post :create_invoices, :project_id => 'onlinestore',
      :draft_ids => [draft.id],
      "draft_#{draft.id}" => IssuedInvoice.next_number(draft.project)
    assert_response :success
    assert_equal draft_count, DraftInvoice.count
    invoice = IssuedInvoice.last
    assert_equal invoices(:template1).invoice_lines.first.taxes.first, invoice.invoice_lines.first.taxes.first
  end
end
