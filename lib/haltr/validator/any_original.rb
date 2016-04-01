module Haltr
  module Validator
    module AnyOriginal

      def self.included(base)
        base.class_eval do
          validate :original_validations,
            if: Haltr::Validator.condition_for(Haltr::Validator::AnyOriginal)
        end
      end

      def original_validations
        # has original file
        # it does not matter if invoice was modified or not
        unless original
          errors.add(:base, I18n.t(:invoice_has_no_original))
        end
      end

    end
  end
end
