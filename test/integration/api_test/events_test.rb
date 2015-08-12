require File.dirname(__FILE__) + '/../../test_helper'

class Redmine::ApiTest::EventsTest < Redmine::ApiTest::Base
  fixtures :invoices, :events

  def setup
    Setting.rest_api_enabled = '1'
  end

  test 'gets file from download_legal_url' do
    e = events('with_file_notes')
    get "/events/file/#{e.id}", {}, credentials('jsmith')
    assert_response :success
    assert_equal 'This is the file content', response.body
    assert_equal "plain/text", response.content_type
    assert_equal "attachment; filename=\"readme.txt\"", response['Content-Disposition']
  end

end
