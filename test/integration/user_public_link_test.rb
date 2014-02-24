require File.dirname(__FILE__) + '/../test_helper'

class UserPublicLinkTest < ActionController::IntegrationTest

  fixtures :companies, :invoices, :invoice_lines, :taxes

  # 855445292 is 'invoice1'

  def test_view_public_link
    get "/projects/onlinestore/invoices/new"
    get "/invoice/a0123456789/855445292"
    assert_response :success
  end

  def test_view_false_public_link
    get "/invoice/a0123456789/101010101"
    assert_response 404
    get "/invoice/10101010101/855445292"
    assert_response 404
  end


end
