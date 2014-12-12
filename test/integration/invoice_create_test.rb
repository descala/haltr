require File.dirname(__FILE__) + '/../test_helper'

class InvoiceCreaeteTest < ActionController::IntegrationTest

  fixtures :companies, :invoices, :invoice_lines, :taxes

  def test_create_new_invoice
    post "/login", :username => 'jsmith', :password => 'jsmith'

    get "/projects/onlinestore/invoices/new"
    assert_response :success

    post "/projects/onlinestore/invoices",
    {
      "commit"=>"Create",
      "action"=>"create",
      "id"=>"onlinestore",
      "controller"=>"invoices",
      "invoice"=>
      {
        "number"=>"invoice_created_test_1",
        "ponumber"=>"",
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
                "code"=>"10.0_S",
                "comment"=>"comment for TAXA 10%"
              },
                "1"=>
              {
                "name"=>"TAXB",
                "code"=>"20.0_S",
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

    invoice = Invoice.find_by_number 'invoice_created_test_1'
    assert_redirected_to :controller => "invoices", :action => "show", :id => invoice
    assert_equal 1, invoice.invoice_lines.size
    assert_equal 2, invoice.invoice_lines.first.taxes.size
    # comments should be blank since taxes not exempt
    assert_equal "", invoice.invoice_lines.first.taxes.first.comment
    assert_equal "", invoice.invoice_lines.first.taxes.last.comment
  end

  def test_create_new_invoice_in_turkish_lira
    post "/login", :username => 'jsmith', :password => 'jsmith'

    get "/projects/onlinestore/invoices/new"
    assert_response :success

    post "/projects/onlinestore/invoices",
    {
      "commit"=>"Create",
      "action"=>"create",
      "id"=>"onlinestore",
      "controller"=>"invoices",
      "invoice"=>
      {
        "number"=>"invoice_created_test_2",
        "ponumber"=>"",
        "accounting_cost"=>"",
        "payment_method"=>"1",
        "charge_amount"=>"",
        "date"=>"2013-02-12",
        "charge_reason"=>"",
        "client_id"=>"404360906",
        "extra_info"=>"",
        "currency"=>"TRY",
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
                "code"=>"10.0_S",
                "comment"=>"comment for TAXA 10%"
              },
                "1"=>
              {
                "name"=>"TAXB",
                "code"=>"20.0_S",
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

    invoice = Invoice.find_by_number 'invoice_created_test_2'
    assert_redirected_to :controller => "invoices", :action => "show", :id => invoice
    assert_equal 1, invoice.invoice_lines.size
    assert_equal 2, invoice.invoice_lines.first.taxes.size
    # comments should be blank since taxes not exempt
    assert_equal "", invoice.invoice_lines.first.taxes.first.comment
    assert_equal "", invoice.invoice_lines.first.taxes.last.comment
  end

end
