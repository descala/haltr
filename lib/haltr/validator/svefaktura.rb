module Haltr
  module Validator
    module Svefaktura

      def self.included(base)
        base.class_eval do
          validate :svefaktura_validations,
            if: Haltr::Validator.condition_for(Haltr::Validator::Svefaktura)
        end
      end

      def svefaktura_validations
        # svefaktura fields
        if respond_to?(:accounting_cost) and accounting_cost.blank?
          errors.add(:base, I18n.t(:missing_svefaktura_account))
        elsif company.company_identifier.blank?
          errors.add(:base, I18n.t(:missing_svefaktura_organization))
        elsif debit?
          errors.add(:base, I18n.t(:missing_svefaktura_debit))
        end
      end

    end
  end
end
