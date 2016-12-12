require File.dirname(__FILE__) + '/../test_helper'

class Dir3EntityTest < ActiveSupport::TestCase
  fixtures :dir3_entities

  test "spaces are removed from code" do
    entity1 = Dir3Entity.new(
      name: 'dir3_entity1',
      code: ' 123456'
    )
    assert entity1.save
    assert_equal '123456', Dir3Entity.last.code
    entity2 = Dir3Entity.new(
      name: 'dir3_entity1',
      code: '123 456'
    )
    assert !entity2.save, "saved dir3 entity with same code"
  end

end
