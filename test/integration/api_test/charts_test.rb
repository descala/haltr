require File.dirname(__FILE__) + '/../../test_helper'

class Redmine::ApiTest::ChartsTest < Redmine::ApiTest::Base
  fixtures :invoices, :clients, :companies

  def setup
    Setting.rest_api_enabled = '1'
  end

  test 'invoice total' do
    get "/invoices/total_chart.json?pref=all_by_year", {}, credentials('jsmith')
    assert_response :success
    assert_equal ["2008", "1851.36"], JSON(response.body)[0]['data'].first
  end

  test 'invoice status' do
    get "/projects/onlinestore/invoice_status_chart.json?pref=all_by_year", {}, credentials('jsmith')
    assert_response :success
    assert_equal ["2008", 0], JSON(response.body)[0]['data'].first
  end

  test 'top clients' do
    # all_by_year
    get "/projects/onlinestore/top_clients_chart.json?pref=all_by_year", {}, credentials('jsmith')
    assert_response :success
    assert_equal ["2011", "1888.0"], JSON(response.body)[0]['data'].first
    # last_month_by_week
    get "/projects/onlinestore/top_clients_chart.json?pref=last_month_by_week", {}, credentials('jsmith')
    assert_response :success
    assert_equal({}, JSON(response.body))
    # all_by_month
    get "/projects/onlinestore/top_clients_chart.json?pref=all_by_month", {}, credentials('jsmith')
    assert_response :success
    assert_equal ["2011/09", "1888.0"], JSON(response.body)[0]['data'].first
    # last_year_by_month / other
    get "/projects/onlinestore/top_clients_chart.json?pref=unknown_pref", {}, credentials('jsmith')
    assert_response :success
    assert_equal [{"name"=>"Client1", "data"=>[["2014/12", "0"]]}], JSON(response.body)
  end

  test 'cash flow' do
    get "/projects/onlinestore/cash_flow.json?pref=all", {}, credentials('jsmith')
    assert_response :success
    assert_equal 1851.36, JSON(response.body)['cash_flow']['invoices_sum']
  end

end
