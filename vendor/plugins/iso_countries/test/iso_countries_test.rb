require 'test/unit'
require "iso_countries"

class IsoCountriesTest < Test::Unit::TestCase
  def test_this_plugin
    assert_equal("Spain", ISO::Countries.get_country("es"))
    assert_equal("es", ISO::Countries.set_language("es"))
    assert_equal("España", ISO::Countries.get_country("es"))
  end
end
