module Haltr
  module Validator
    module Original

      def self.included(base)
        base.class_eval do
          validate :original_validations,
            if: Haltr::Validator.condition_for(Haltr::Validator::Original)
        end
      end

      def original_validations
        # has original file
        unless (original.present? rescue true)
          errors.add(:base, I18n.t(:invoice_has_no_original))
        end
      end

    end
  end
end
