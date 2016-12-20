require File.expand_path('../../test_helper', __FILE__)

class InvoicesHelperTest < ActionView::TestCase

  include HaltrHelper

  test "number_to_currency of a Money object and locales" do
    set_language_if_valid 'es'
    import = Money.new(123456,'EUR')
    assert_equal('1.234,56 €',money(import))
  end

end
