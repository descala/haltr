class HaltrMailHandlerController < ApplicationController


  before_filter :authorize_global
  accept_api_auth :check_mail

  # Retrieves new mails from configured inbox (in config/configuration.yml)
  # supports bounces for sent invoices, importing attached invoices
  def check_mail
    domain = Redmine::Configuration['haltr_mail_handler_domain']
    Mailman.config.imap = {
      server:   Redmine::Configuration['haltr_mail_handler_server'],
      port:     Redmine::Configuration['haltr_mail_handler_port'],
      username: Redmine::Configuration['haltr_mail_handler_username'],
      password: Redmine::Configuration['haltr_mail_handler_password']
    }
    # disable polling
    Mailman.config.poll_interval = 0

    processed = []
    Mailman::Application.run do
      to("%recipient%@#{domain}") do
        # Avoid warning:
        #   Non US-ASCII detected and no charset defined.
        #   Defaulting to UTF-8, set your own if this is incorrect.
        message.charset = 'UTF-8'
        message.content_transfer_encoding = '8bit'

        processed << "processed mail [#{message.message_id}] from '#{message.from}' with subject '#{message.subject}'"
        processed << HaltrMailHandler.receive(message)
      end
      default do
        Rails.logger.info "Unknown recipient #{message.to} for message with id #{message.message_id}"
      end
    end
    Rails.logger.info processed.join("\n") if processed.any?
    render text: processed.join("\n")
  end

end

