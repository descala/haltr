module Haltr
  module Validator
    module Imap

      def self.validate(invoice)
        #TODO: invoice.add_export_error?
        # check that company has imap config
        invoice.company and
          !invoice.company.imap_host.blank? and
          !invoice.company.imap_username.blank? and
          !invoice.company.imap_password.blank? and
          !invoice.company.imap_port.nil?
      end

    end
  end
end
