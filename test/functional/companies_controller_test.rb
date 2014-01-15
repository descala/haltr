require File.dirname(__FILE__) + '/../test_helper'

class CompaniesControllerTest < ActionController::TestCase

  fixtures :companies, :taxes

  def test_edit_my_company
    @request.session[:user_id] = 2
    get :my_company, :project_id => 'onlinestore'
    assert_response :success
    assert_template 'edit'
  end

  def test_save_company_with_invalid_taxes
    user = User.find 2
    @request.session[:user_id] = user.id
    put(:update,
      {
                "commit" => "Desa",
                    "id" => companies('company1').id ,
               "company" => {
                 "taxcode" => "1234567",
      "company_identifier" => "",
                    "name" => "Company1",
                   "email" => "test@test.com",
                 "address" => "",
                    "city" => "",
              "postalcode" => "08080",
                "province" => "",
                 "country" => "es",
                 "website" => "",
          "invoice_format" => "aoc",
                "currency" => "EUR",
                  "public" => "private",
       "taxes_attributes"  => {
                         "0" => {
                        "name" => "IVA",
                     "percent" => "18.0",
                     "default" => "1",
                    "category" => "S",
                    "_destroy" => "",
                     "comment" => ""
                                },
                         "1" => {
                        "name" => "IVA",
                     "percent" => "18.0",
                     "default" => "0",
                    "category" => "S",
                    "_destroy" => "",
                     "comment" => ""
                                }
                              }
                            },
      })
    assert_equal ['is invalid'],
             assigns(:company).errors.messages[:taxes]
  end

end
