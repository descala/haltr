module Haltr
  module Validator
    module Mail

      def self.included(base)
        base.class_eval do
          validate :mail_validations,
            if: Haltr::Validator.condition_for(Haltr::Validator::Mail)
        end
      end

      def mail_validations
        # skip validation on new_record, to prevent import errors
        # https://www.ingent.net/issues/6017
        # we need a mail to send invoice to
        unless recipient_emails.any? or new_record?
          errors.add(:base, I18n.t(:client_has_no_email))
        end
      end

    end
  end
end
