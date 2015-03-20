module Haltr
  module Validator
    module Mail

      def self.validate(invoice)
        # we need a mail to send invoice to
        unless invoice.recipient_emails.any?
          invoice.add_export_error(:client_has_no_email)
        end
      end

    end
  end
end
