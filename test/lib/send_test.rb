require File.dirname(__FILE__) + '/../test_helper'

class SendTest < ActiveSupport::TestCase

  fixtures :taxes, :companies, :invoices, :invoice_lines, :clients, :people

  test "just call empty perform" do
    assert_equal nil, Haltr::GenericSender.new.perform
  end

  test "just call SendPdfByMail" do
    assert Haltr::SendPdfByMail.new(invoices(:invoices_001),User.find(2)).perform
    mail = last_email
    assert mail.to.include?('person1@example.com')
    assert mail.to.include?('mail@client1.com')
  end

  test "just call SendPdfByIMAP" do
    # does not send the email, just stores it in an IMAP folder
    mail = Haltr::SendPdfByIMAP.new(invoices(:invoices_001),User.find(2)).perform
    assert mail.to.include?('person1@example.com')
    assert mail.to.include?('mail@client1.com')
  end

  private

  def last_email
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    mail
  end

end
