module Haltr
  module Validator
    module Peppol

      def self.included(base)
        base.class_eval do
          validate :peppol_validations,
            if: Haltr::Validator.condition_for(Haltr::Validator::Peppol)
        end
      end

      def peppol_validations
        # peppol required fields
        if client.schemeid.blank? or client.endpointid.blank?
          errors.add(:base, I18n.t(:missing_client_peppol_fields))
        elsif company.schemeid.blank? or company.endpointid.blank?
          errors.add(:base, I18n.t(:missing_company_peppol_fields))
        end
      end

    end
  end
end
