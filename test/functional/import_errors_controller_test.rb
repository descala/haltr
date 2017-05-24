require File.expand_path('../../test_helper', __FILE__)

class ImportErrorsControllerTest < ActionController::TestCase
  fixtures :companies, :invoices, :import_errors

  def setup
    User.current = nil
    Setting.rest_api_enabled = '1'
  end

  test 'require auth' do
    get :index, project_id: 'onlinestore'
    assert_redirected_to '/login?back_url=http%3A%2F%2Ftest.host%2Fprojects%2Fonlinestore%2Fimport_errors'
  end

  test 'create import_error' do
    initial_count = Project.find(2).import_errors.count
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
    assert_equal initial_count+1, Project.find(2).import_errors.count
  end

  test 'truncates import_errors when it is too long (:limit => 65535)' do
    post :create, {
      format: :json,
      project_id: 2,
      key: User.find_by_login('jsmith').api_key,
      import_error: {
        filename: 'file.txt',
        import_errors: 'X'*65900,
        original: 'text'
      }
    }
    assert_match(/Import error truncated to 65000 characters/, Project.find(2).import_errors.last.import_errors)
  end
end
