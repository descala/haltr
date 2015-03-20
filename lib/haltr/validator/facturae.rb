module Haltr
  module Validator
    module Facturae

      def self.validate(invoice)
        # facturae 3.x needs taxes to be valid
        invoice.invoice_lines.each do |line|
          unless line.taxes_outputs.any?
            invoice.add_export_error(:invoice_has_no_taxes)
          end
        end

        # facturae needs taxcodes
        if invoice.company.taxcode.blank?
          invoice.add_export_error(:company_taxcode_needed)
        end
        if invoice.client.taxcode.blank?
          invoice.add_export_error(:client_taxcode_needed)
        end

        # facturae needs postalcode
        if invoice.client.postalcode.blank?
          invoice.add_export_error(:client_postalcode_needed)
        end

        # facturae payment method requirements
        if invoice.debit?
          c = invoice.client
          if c.bank_account.blank? and !c.use_iban?
            invoice.add_export_error([:field_payment_method, :requires_client_bank_account])
          end
        elsif invoice.transfer?
          bank_info = invoice.bank_info
          if !bank_info or (bank_info.bank_account.blank? and bank_info.iban.blank?)
            invoice.add_export_error([:field_payment_method, :requires_company_bank_account])
          elsif (bank_info.bank_account.blank? and !bank_info.use_iban?)
            invoice.add_export_error([:field_payment_method, :requires_company_bank_account])
            invoice.add_export_error([:bank_info, 'activerecord.errors.messages.invalid'])
          end
        end
        unless invoice.payment_method.blank?
          if invoice.due_date.blank?
            invoice.add_export_error([:field_due_date, 'activerecord.errors.messages.blank'])
          end
        end
      end

    end
  end
end
