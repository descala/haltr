require File.dirname(__FILE__) + '/../test_helper'

class InvoiceCreaeteTest < ActionController::IntegrationTest

  def test_create_new_invoice
    post "/login", :username => 'jsmith', :password => 'jsmith'
    assert_redirected_to "/my/page"

    get "/invoices/new/onlinestore"
    assert_response :success

    post "/invoices/create/onlinestore",
    {
      "commit"=>"Create",
      "VAT_global"=>"0.0_E",
      "action"=>"create",
      "id"=>"onlinestore",
      "controller"=>"invoices",
      "invoice"=>
      {
        "discount_percent"=>"0",
        "number"=>"invoices_003",
        "ponumber"=>"",
        "discount_text"=>"",
        "accounting_cost"=>"",
        "payment_method"=>"1",
        "charge_amount"=>"",
        "date"=>"2013-02-12",
        "charge_reason"=>"",
        "client_id"=>"404360906",
        "extra_info"=>"",
        "currency"=>"EUR",
        "terms"=>"0",
        "payment_method_text"=>"",
        "invoice_lines_attributes"=>
        {
          "0"=>
          {
            "price"=>"10",
            "tax_VAT"=>"0.0_E",
            "quantity"=>"1",
            "unit"=>"1",
            "description"=>"item"
          }
        },
      },
    }

    assert_redirected_to :controller => "invoices", :action => "show" #TODO: id?
  end

end
