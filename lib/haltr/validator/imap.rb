module Haltr
  module Validator
    module Imap

      def self.included(base)
        condition = Proc.new {|invoice|
          return false unless invoice.client
          ExportChannels.validators(
            invoice.client.invoice_format
          ).include?(Haltr::Validator::Imap)
        }
        base.class_eval do
          validate :company_has_imap_config, if: condition
        end
      end

      def company_has_imap_config
        unless invoice.company and
            !invoice.company.imap_host.blank? and
            !invoice.company.imap_username.blank? and
            !invoice.company.imap_password.blank? and
            !invoice.company.imap_port.nil?
          errors.add(:base, I18n.t(:missing_imap_config))
        end
      end

    end
  end
end
