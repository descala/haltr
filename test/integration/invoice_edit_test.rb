require File.dirname(__FILE__) + '/../test_helper'

class InvoiceEditTest < ActionController::IntegrationTest

   # TODO fixtures here break other tests ???

  def test_edit_invoice_tax_with_comment
    post "/login", :username => 'jsmith', :password => 'jsmith'
    assert_redirected_to "/my/page"

    # This is a simple invoice. 100 EUR with a 10% VAT tax
    get "/invoices/4"
    assert_response :success

    post "/invoices/4",
      {
      "commit"=>"Save",
      "controller"=>"invoices",
      "_method"=>"put",
      "id"=>"4",
      "invoice"=>
      {
        "date"=>"2011-09-13",
        "discount_percent"=>"0",
        "payment_method"=>"1",
        "charge_reason"=>"",
        "extra_info"=>"This is a simple invoice. 100 EUR with a 10% VAT tax",
        "number"=>"i4",
        "discount_text"=>"",
        "accounting_cost"=>"",
        "ponumber"=>"client order number 123",
        "terms"=>"0",
        "currency"=>"EUR",
        "payment_method_text"=>"",
        "client_id"=>"404360906",
        "charge_amount"=>"",
        "invoice_lines_attributes"=>
        {
          "0"=>
          {
            "taxes_attributes"=>
            {
              "0"=>
              {
                "name"=>"VAT",
                "code"=>"0.0_E",
                "comment"=>"Exempt because we do not have to pay it",
                "id"=>"363578707"
              },
              "1"=>
              {
                "name"=>"OTH",
                "code"=>"",
                "comment"=>"this tax is not applicable and should not be saved"
              }
            },
              "quantity"=>"1",
              "unit"=>"1",
              "price"=>"100",
              "description"=>"Line 1 of invoice i4",
              "id"=>"444794029"
          }
        }
      }
    }

    assert_redirected_to "/invoices/4"

    invoice = Invoice.find(4)
    assert_kind_of IssuedInvoice, invoice
    assert_equal 1, invoice.invoice_lines.size
    assert_equal 1, invoice.invoice_lines.first.taxes.size

    # Tax comment should be copied if category is E
    tax = invoice.invoice_lines.first.taxes.first
    assert_kind_of Tax, tax
    assert_equal 0.0, tax.percent
    assert_equal "Exempt because we do not have to pay it", tax.comment

    # tax category should be preserved
    assert_equal 'E', tax.category
  end

end
