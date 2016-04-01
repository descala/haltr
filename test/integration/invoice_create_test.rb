require File.dirname(__FILE__) + '/../test_helper'

class InvoiceCreaeteTest < ActionController::IntegrationTest

  fixtures :companies, :invoices, :invoice_lines, :taxes, :client_offices,
    :dir3_entities

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

    invoice = Invoice.last
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

    invoice = Invoice.last
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

    invoice = Invoice.last
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

  def test_create_new_invoice_with_dir3
    assert_equal 3, Dir3Entity.count
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
        },
        "oficina_comptable" => {
          "code" => "A01004456",
          "address" => "CTR.DE LA ESCLUSA,S/N MOD.A",
          "postalcode" => "41011",
          "city" => "SEVILLA",
          "province" => "Sevilla",
          "country" => "ESP",
          "name" => "Oficina Contable"
        },
        "organ_gestor" => {
          "code" => "GE0000266",
          "address" => "CTR. DE LA ESCLUSA, S/N",
          "postalcode" => "41012",
          "city" => "SEVILLA",
          "province" => "Sevilla",
          "country" => "ESP",
          "name" => "Centro Gestor"
        },
        "unitat_tramitadora" => { # existing dir3_entity on fixtures
          "code" => "A09006151",
          "address" => "address",
          "postalcode" => "postalcode",
          "city" => "city",
          "province" => "province",
          "country" => "country",
          "name" => "name"
        }
      }
    }

    invoice = Invoice.last
    assert_redirected_to :controller => "invoices", :action => "show", :id => invoice

    # it created 2 new dir3_entities
    assert_equal 5, Dir3Entity.count
    dir3 = Dir3Entity.find_by_code('A01004456')
    assert_not_nil dir3
    assert_equal 'CTR.DE LA ESCLUSA,S/N MOD.A', dir3.address
    assert_equal '41011', dir3.postalcode
    assert_equal 'SEVILLA', dir3.city
    assert_equal 'Sevilla', dir3.province
    assert_equal 'es', dir3.country
    assert_equal 'Oficina Contable', dir3.name
    dir3 = Dir3Entity.find_by_code('GE0000266')
    assert_not_nil dir3
    assert_equal 'CTR. DE LA ESCLUSA, S/N', dir3.address
    assert_equal '41012', dir3.postalcode
    assert_equal 'SEVILLA', dir3.city
    assert_equal 'Sevilla', dir3.province
    assert_equal 'es', dir3.country
    assert_equal 'Centro Gestor', dir3.name

    # it uses existing dir3 and does not update its attributes
    dir3 = Dir3Entity.find_by_code('A09006151') # existing dir3_entity fixture
    assert_not_nil dir3
    assert_equal 'Adreça 1', dir3.address
    assert_equal '08080', dir3.postalcode
    assert_equal 'Barcelona', dir3.city
    assert_equal 'Barcelona', dir3.province
    assert_equal 'es', dir3.country
    assert_equal 'Unitat tramitadora', dir3.name

    assert_equal 'A01004456', invoice.oficina_comptable
    assert_equal 'GE0000266', invoice.organ_gestor
    assert_equal 'A09006151', invoice.unitat_tramitadora
  end

  def test_create_new_invoice_with_factoring
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
          "country" => "ESP"
        },
        "fa_person_type"    => 'F',
        "fa_residence_type" => 'R',
        "fa_taxcode"        => 'ESP4802400D',
        "fa_name"           => 'fa name',
        "fa_address"        => 'fa address',
        "fa_postcode"       => '08080',
        "fa_town"           => 'barcelona',
        "fa_province"       => 'barcelona',
        "fa_country"        => 'ESP',
        "fa_info"           => 'fa info',
        "fa_duedate"        => '2015-01-01',
        "fa_import"         => '100',
        "fa_payment_method" => '01',
        "fa_iban"           => '1234567890',
        "fa_bank_code"      => '123',
        "fa_clauses"        => 'fa clauses',
      }
    }

    invoice = Invoice.last
    assert_equal 'F',          invoice.fa_person_type
    assert_equal 'R',          invoice.fa_residence_type
    assert_equal 'ESP4802400D',invoice.fa_taxcode
    assert_equal 'fa name',    invoice.fa_name
    assert_equal 'fa address', invoice.fa_address
    assert_equal '08080',      invoice.fa_postcode
    assert_equal 'barcelona',  invoice.fa_town
    assert_equal 'barcelona',  invoice.fa_province
    assert_equal 'fa info',    invoice.fa_info
    assert_equal 100,            invoice.fa_import
    assert_equal '01',         invoice.fa_payment_method
    assert_equal '1234567890', invoice.fa_iban
    assert_equal '123',        invoice.fa_bank_code
    assert_equal 'fa clauses', invoice.fa_clauses

    assert_equal 'es',         invoice.client.country
    assert_equal 'es',         invoice.fa_country
    assert_equal Date.new(2015,1,1), invoice.fa_duedate
    assert_redirected_to :controller => "invoices", :action => "show", :id => invoice

    assert_equal 'F', invoice.fa_person_type
  end

end
