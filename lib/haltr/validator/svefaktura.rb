module Haltr
  module Validator
    module Svefaktura

      def self.validate(invoice)
        Ubl.validate(invoice)
        # svefaktura fields
        if invoice.respond_to?(:accounting_cost) and invoice.accounting_cost.blank?
          invoice.add_export_error(:missing_svefaktura_account)
        elsif invoice.company.company_identifier.blank?
          invoice.add_export_error(:missing_svefaktura_organization)
        elsif invoice.debit?
          invoice.add_export_error(:missing_svefaktura_debit)
        end
      end

    end
  end
end
