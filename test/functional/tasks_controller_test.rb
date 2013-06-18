 require File.dirname(__FILE__) + '/../test_helper'
 
 class TasksControllerTest < ActionController::TestCase

   fixtures :invoices

   def test_n19
     Haltr::TestHelper.fix_invoice_totals
     @request.session[:user_id] = 2
     get "n19", :id => invoices(:invoice1)
     assert_response :success
     assert_template 'tasks/n19'
     assert_not_nil assigns(:due_date)
     assert_equal 'text/plain', @response.content_type
     lines = @response.body.chomp.split("\n")
     # spaces are relevant
     assert_equal '568077310000G000B00000000   SOME NON ASCII CHARS  LONG NAME THAT MAY114910865126953221150000092568                FRA 08/001                        925,68        ', lines[2]
   end
 
 end
