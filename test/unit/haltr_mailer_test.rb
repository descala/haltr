# encoding: utf-8

require File.dirname(__FILE__) + '/../test_helper'

class HaltrMailerTest < ActiveSupport::TestCase

  fixtures :invoices

  include Redmine::I18n
  include ActionDispatch::Assertions::SelectorAssertions
  include Rails.application.routes.url_helpers

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
    assert_equal 'Invoice_08_001.pdf',  mail.header['X-Haltr-Filename'].to_s
    assert_equal "722d813699ee44602f647997b055fa2a", mail.header['X-Haltr-MD5'].to_s
    assert_equal User.current.id.to_s,  mail.header['X-Haltr-Sender'].to_s
    assert_equal Setting.plugin_haltr['invoice_mail_subject'], mail.subject
    assert_mail_body_match Setting.plugin_haltr['invoice_mail_body'], mail

    assert_select_email do
      # public link to invoice
      assert_select 'a[href=?]',
        "#{Setting.protocol}://#{Setting.host_name}/invoice/#{invoice.client.hashid}/#{invoice.id}",
        :text => "#{Setting.protocol}://#{Setting.host_name}/invoice/#{invoice.client.hashid}/#{invoice.id}"
    end

    assert mail.has_attachments?, "mail has no attached invoice!"
    assert_equal 1,                    mail.attachments.size
    assert_equal 'Invoice_08_001.pdf', mail.attachments[0].filename
    assert_match(/^application\/pdf/,  mail.attachments[0].content_type)
  end

  private

  def last_email
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    mail
  end


end
