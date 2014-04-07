require File.dirname(__FILE__) + '/../test_helper'

class SendTest < ActiveSupport::TestCase

  fixtures :taxes, :companies, :invoices, :invoice_lines, :clients

  include Haltr::IMAP

  test "just call empty perform" do
    assert_equal nil, Haltr::GenericSender.new.perform
  end

  test "just call SendSignedPdfByMail" do
    assert Haltr::SendSignedPdfByMail.new(invoices(:invoices_001),User.find(2)).perform
    mail = last_email
    assert mail.to.include?('person1@example.com')
  end

  test "just call SendSignedPdfByIMAP" do
    # TODO do not connect to IMAP in testing
    assert Haltr::SendSignedPdfByIMAP.new(invoices(:invoices_001),User.find(2)).perform
  end

  private

  def last_email
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    mail
  end

end
