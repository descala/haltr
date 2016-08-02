require File.dirname(__FILE__) + '/../test_helper'

class ClientCreaeteTest < Redmine::IntegrationTest

  fixtures :clients

  def test_create_new_invoice_with_unicode_character_in_iban
    post "/login", :username => 'jsmith', :password => 'jsmith'

    get "/projects/onlinestore/clients/new"
    assert_response :success

    post "/projects/onlinestore/clients",
      {
      "commit"=>"Create",
      "action"=>"create",
      "id"=>"onlinestore",
      "controller"=>"invoices",
      "client"=>{
        "taxcode"=>"S0811001G",
        "company_identifier"=>"comidentif",
        "name"=>"compname",
        "email"=>"email@example.com",
        "website"=>"www.website.com",
        "address"=>"addr1",
        "address2"=>"addr2",
        "postalcode"=>"08080",
        "city"=>"Barcelona",
        "province"=>"Barcelona",
        "country"=>"es",
        "language"=>"ca",
        "currency"=>"EUR",
        "invoice_format"=>"signed_pdf",
        "iban"=>"ES80 \u200b2310 0001 1800 0001 2345",
        "bic"=>"12312345",
        "payment_method"=>"1",
        "payment_method_text"=>"",
        "terms"=>"0",
        "sepa_type"=>"CORE",
        "schemeid"=>"AT:CID",
        "endpointid"=>""
      },
    }

    client = Client.find_by_taxcode 'ESS0811001G'
    assert client
    assert_redirected_to :controller=>"clients", :action=>"show", :id=>client
  end

end
