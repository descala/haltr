require File.expand_path('../../test_helper', __FILE__)

class PersonTest < ActiveSupport::TestCase

  fixtures :people

  test "find a person" do
    p1 = people(:person1)
    assert p1
    assert_equal Person, p1.class
    assert_equal "Smith", p1.last_name
  end

end
