module Haltr
  module Validator
    module Ubl

      def self.validate(invoice)
        # has no taxes withheld
        if invoice.taxes_withheld.any?
          invoice.add_export_error(:ubl_invoice_has_taxes_withheld)
        end
      end

    end
  end
end
