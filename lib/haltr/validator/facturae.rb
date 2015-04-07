module Haltr
  module Validator
    module Facturae

      def self.included(base)
        base.class_eval do
          validates_length_of :file_reference, maximum: 20
          validates_length_of :accounting_cost, maximum: 40
          validates_length_of :delivery_note_number, maximum: 30
          validate :custom_validations
          validates_associated :client
        end
      end

      def custom_validations
        # facturae 3.x needs taxes to be valid
        invoice_lines.each do |line|
          unless line.taxes_outputs.any?
            errors.add(:base, I18n.t(:invoice_has_no_taxes))
          end
        end

        # facturae needs taxcodes
        if company.taxcode.blank?
          errors.add(:base, I18n.t(:company_taxcode_needed))
        end
        if client.taxcode.blank?
          client.errors.add(:taxcode, :blank)
        end

        # facturae needs postalcode, with size 5
        if client.postalcode.blank?
          client.errors.add(:postalcode, :blank)
        elsif client.postalcode.size != 5
          client.errors.add(:postalcode, :blank)
        end

        # facturae payment method requirements
        if debit?
          c = client
          if c.bank_account.blank? and !c.use_iban?
            errors.add(:field_payment_method, I18n.t(:requires_client_bank_account))
          end
        elsif transfer?
          bank_info = bank_info
          if !bank_info or (bank_info.bank_account.blank? and bank_info.iban.blank?)
            errors.add(:field_payment_method, I18n.t(:requires_company_bank_account))
          elsif (bank_info.bank_account.blank? and !bank_info.use_iban?)
            errors.add(:field_payment_method, I18n.t(:requires_company_bank_account))
            bank_info.errors.add(:base, :invalid)
          end
        end
        unless payment_method.blank?
          if due_date.blank?
            errors.add(:field_due_date, :blank)
          end
        end
      end

    end
  end
end
