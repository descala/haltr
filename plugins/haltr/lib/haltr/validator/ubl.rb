module Haltr
  module Validator
    module Ubl

      def self.included(base)
        base.class_eval do
          validate :ubl_validations,
            if: Haltr::Validator.condition_for(Haltr::Validator::Ubl)
        end
      end

      def ubl_validations
        # has no taxes withheld
        if taxes_withheld.any?
          errors.add(:base, I18n.t(:ubl_invoice_has_taxes_withheld))
        end
      end

    end
  end
end
