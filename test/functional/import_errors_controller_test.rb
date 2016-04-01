require File.dirname(__FILE__) + '/../test_helper'

class ImportErrorsControllerTest < ActionController::TestCase
  fixtures :companies, :invoices, :import_errors

  def setup
    User.current = nil
  end

  test 'require auth' do
    get :index, project_id: 'onlinestore'
    assert_redirected_to '/login?back_url=http%3A%2F%2Ftest.host%2Fprojects%2Fonlinestore%2Fimport_errors'
  end

  test 'create import_error' do
    initial_count = ImportError.count
    post :create, {
      format: :json,
      project_id: 2,
      key: User.find_by_login('jsmith').api_key,
      import_error: {
        filename: 'file.txt',
        import_errors: 'errors',
        original: 'text'
      }
    }
    assert_equal 'application/json', response.content_type
    assert_response :success
    assert_equal initial_count+1, ImportError.count
  end

end
