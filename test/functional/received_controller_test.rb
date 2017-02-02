require File.expand_path('../../test_helper', __FILE__)

class ReceivedControllerTest < ActionController::TestCase
  fixtures :companies, :invoices, :invoice_lines, :taxes

  def setup
    User.current = nil
    @request.session[:user_id] = 2
  end

  test "show received pdf invoice" do
    get :show, :id => invoices(:received_1)
  end

  test "show accepted xml invoice" do
    get :show, :id => invoices(:received_2)
  end

  test 'update received invoice' do
    put :update, invoice: {
      client_id: '',
      total: '0,00',
      number: '',
      date: '',
      due_date: '',
      invoice_lines_attributes: {
        '0' => {
          price: '',
          tax_percent: '30',
          tax_import: '31',
          tax_category: 'S',
          tax_wh_percent: '16',
          tax_wh_import: '17',
          tax_wh_category: 'S',
          quantity: '1',
          _destroy: ''
        }
      }
    },
    id: '10'
    #assert_response :success
    invoice = invoices(:received_1)
    assert_equal 1, invoice.invoice_lines.size
    assert_equal 2, invoice.invoice_lines.first.taxes.size
    iva = invoice.invoice_lines.first.taxes.where(name: 'IVA').first
    irpf = invoice.invoice_lines.first.taxes.where(name: 'IRPF').first
    assert_equal 30, iva.percent.to_i
    assert_equal 31, iva.import.to_i
    assert_equal 'S', iva.category
    assert_equal(-16, irpf.percent.to_i)
    assert_equal(-17, irpf.import.to_i)
    assert_equal 'S', irpf.category
  end

end
