# encoding: utf-8

require File.expand_path('../../test_helper', __FILE__)

class HaltrMailerTest < ActiveSupport::TestCase

  fixtures :invoices

  include Redmine::I18n
  include Rails::Dom::Testing::Assertions

  def setup
    ActionMailer::Base.deliveries.clear
  end

  def test_invoice_email
    invoice = invoices(:invoice1)
    pdf = File.read(Rails.root.join('plugins','haltr','test','fixtures','documents','invoice_pdf_signed.pdf'))
    assert HaltrMailer.send_invoice(invoice,{:pdf=>pdf}).deliver

    mail = last_email
    assert_not_nil mail

    assert_equal invoice.company.email, mail.from_addrs.first
    assert_equal invoice.client.email,  mail.to_addrs.first
    assert_equal invoice.id.to_s,       mail.header['X-Haltr-Id'].to_s
    assert_equal 'Invoice-08001.pdf',   mail.header['X-Haltr-PDF-Filename'].to_s
    assert_equal "722d813699ee44602f647997b055fa2a", mail.header['X-Haltr-PDF-MD5'].to_s
    assert_equal User.current.id.to_s,  mail.header['X-Haltr-Sender'].to_s
    assert_equal invoice.company.invoice_mail_subject(invoice.client.language,invoice), mail.subject
    invoice.company.invoice_mail_body(invoice.client.language,invoice).gsub(/@invoice_url/,'').split.each do |line|
      assert_mail_body_match line, mail
    end

    assert_select_email do
      # public link to invoice
      assert_select 'a[href=?]',
        "#{Setting.protocol}://#{Setting.host_name}/invoice/#{invoice.client.hashid}/#{invoice.id}",
        :text => "#{Setting.protocol}://#{Setting.host_name}/invoice/#{invoice.client.hashid}/#{invoice.id}"
    end

    assert mail.has_attachments?, "mail has no attached invoice!"
    assert_equal 1,                    mail.attachments.size
    assert_equal 'Invoice-08001.pdf',  mail.attachments[0].filename
    assert_match(/^application\/pdf/,  mail.attachments[0].content_type)
  end

  private

  def last_email
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    mail
  end


end
