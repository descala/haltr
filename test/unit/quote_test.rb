# encoding: utf-8
require File.dirname(__FILE__) + '/../test_helper'

class QuoteTest < ActiveSupport::TestCase

  fixtures :clients, :invoices, :invoice_lines, :taxes, :companies, :people, :bank_infos

  def setup
    User.current = nil
    Haltr::TestHelper.fix_invoice_totals
  end

  test "" do
    #
  end

end
