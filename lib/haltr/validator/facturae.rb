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

        # facturae needs postalcode, with size 5
        if invoice.client.postalcode.blank?
          invoice.add_export_error(:client_postalcode_needed)
        elsif invoice.client.postalcode.size != 5
          invoice.add_export_error([:field_postalcode, ['activerecord.errors.messages.wrong_length', count: 5]])
        end

        # file_reference max 20 chars
        if invoice.file_reference.to_s.size > 20
          invoice.add_export_error([:field_file_reference, ['activerecord.errors.messages.too_long', count: 20]])
        end

        # accounting_cost max 40 chars
        if invoice.accounting_cost.to_s.size > 40
          invoice.add_export_error([:field_accounting_cost], ['activerecord.errors.messages.too_long', count: 40])
        end

        # delivery_note_number max 30 chars
        if invoice.delivery_note_number.to_s.size > 40
          invoice.add_export_error([:field_delivery_note_number], ['activerecord.errors.messages.too_long', count: 30])
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
