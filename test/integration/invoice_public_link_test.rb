require File.dirname(__FILE__) + '/../test_helper'

class InvoicePublicLinkTest < ActionController::IntegrationTest

  fixtures :companies, :invoices, :invoice_lines, :taxes

  # 855445292 is 'invoice1'

  def test_view_public_link
    get "www.google.es"
  end

end
