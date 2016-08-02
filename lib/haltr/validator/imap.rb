module Haltr
  module Validator
    module Imap

      def self.included(base)
        condition = Proc.new {|invoice|
          if invoice.client
            ExportChannels.validators(
              invoice.client.invoice_format
            ).include?(Haltr::Validator::Imap)
          else
            false
          end
        }
        base.class_eval do
          validate :company_has_imap_config, if: condition
        end
      end

      def company_has_imap_config
        unless company and
            !company.imap_host.blank? and
            !company.imap_username.blank? and
            !company.imap_password.blank? and
            !company.imap_port.nil?
          errors.add(:base, I18n.t(:missing_imap_config))
        end
      end

    end
  end
end
