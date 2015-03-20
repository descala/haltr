module Haltr
  module Validator
    module Peppol

      def self.validate(invoice)
        # peppol required fields
        if invoice.client.schemeid.blank? or invoice.client.endpointid.blank?
          invoice.add_export_error(:missing_client_peppol_fields)
        elsif invoice.company.schemeid.blank? or invoice.company.endpointid.blank?
          invoice.add_export_error(:missing_company_peppol_fields)
        end
      end

    end
  end
end
