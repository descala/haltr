require File.expand_path('../../../test_helper', __FILE__)

class XmlTest < ActiveSupport::TestCase

  fixtures :invoices, :dir3_entities

  test "generate facturae3x" do
    assert_not_nil Haltr::Xml.generate(invoices(:invoices_001),'facturae30')
    assert_not_nil Haltr::Xml.generate(invoices(:invoices_001),'facturae31')
    assert_not_nil Haltr::Xml.generate(invoices(:invoices_001),'facturae32')
  end

  test "generate ubl" do
    assert_not_nil Haltr::Xml.generate(invoices(:invoices_001), 'peppolubl20')
    assert_not_nil Haltr::Xml.generate(invoices(:invoices_001), 'peppolubl21')
    assert_not_nil Haltr::Xml.generate(invoices(:invoices_001), 'biiubl20')
    assert_not_nil Haltr::Xml.generate(invoices(:invoices_001), 'svefaktura')
    assert_not_nil Haltr::Xml.generate(invoices(:invoices_001), 'oioubl20')
    assert_not_nil Haltr::Xml.generate(invoices(:invoices_001), 'efffubl')
  end

  test "generate facturae32 with dir3" do
    assert_match(/<AdministrativeCentre.*<AdministrativeCentre.*<AdministrativeCentre/m,
      Haltr::Xml.generate(invoices(:i12),'facturae32'))
  end

  test "generate UBL without payment_method" do
    i=invoices(:invoices_001)
    i.payment_method=nil
    assert_nil i.payment_method
    assert_not_nil Haltr::Xml.generate(i, 'peppolubl21')
  end

end
