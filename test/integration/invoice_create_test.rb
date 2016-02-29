require File.dirname(__FILE__) + '/../test_helper'

class InvoiceCreaeteTest < ActionController::IntegrationTest

  fixtures :companies, :invoices, :invoice_lines, :taxes, :client_offices

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
        "discount_percent"=>"0",
        "number"=>"invoice_created_test_2",
        "ponumber"=>"",
        "discount_text"=>"",
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

  def test_create_new_invoice_with_client_office
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
        "discount_percent"=>"0",
        "number"=>"invoice_created_test_1",
        "ponumber"=>"",
        "discount_text"=>"",
        "accounting_cost"=>"",
        "payment_method"=>"2",
        "charge_amount"=>"",
        "date"=>"2013-02-12",
        "charge_reason"=>"",
        "extra_info"=>"",
        "currency"=>"EUR",
        "due_date"=>"2016-05-15",
        "bank_account"=>"20811234761234567890",
        "payment_method_text"=>"",
        "invoice_lines_attributes"=>
        [
          {
            "taxes_attributes"=>
            [
              {
                "name"=>"TAXA",
                "code"=>"10.0_S",
                "comment"=>"comment for TAXA 10%"
              },
              {
                "name"=>"TAXB",
                "code"=>"20.0_S",
                "comment"=>"coment for TAXB 20%"
              }
            ],
            "quantity"=>"1",
            "unit"=>"1",
            "price"=>"100",
            "description"=>"This line has two taxes TAX1 and TAX2 "
          }
        ],
        "client" => {
          "taxcode" => 'B10317980',
          "name" => 'name on client_office',
          "destination_edi_code" => '12345678901234',
          "postalcode" => '08080',
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
    assert_equal(404360906, invoice.client.id)
    assert_equal(1, invoice.client.client_offices.size)
    assert_equal(invoice.client.client_offices.first.id, invoice.client_office.id)
    assert_equal("12345678901234", invoice.client_office.destination_edi_code)
    assert_equal("2016-05-15", invoice.due_date.strftime("%Y-%m-%d"))
  end

end
