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
      "action"=>"create",
      "id"=>"onlinestore",
      "controller"=>"invoices",
      "invoice"=>
      {
        "discount_percent"=>"0",
        "number"=>"invoice_created_test_1",
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
            "taxes_attributes"=>
            {
              "0"=>
              {
                "name"=>"TAXA",
                "percent"=>"10.0",
                "category"=>"S",
                "comment"=>"comment for TAXA 10%"
              },
                "1"=>
              {
                "name"=>"TAXB",
                "percent"=>"20.0",
                "category"=>"S",
                "comment"=>"coment for TAXB 20%"
              }
            },
              "quantity"=>"1",
              "unit"=>"1",
              "price"=>"100",
              "description"=>"This line has two taxes TAX1 and TAX2 "
          }
        }
      }
    }

    i = Invoice.find_by_number 'invoice_created_test_1'
    assert_redirected_to :controller => "invoices", :action => "show", :id => i

    puts i.to_s
  end

end
