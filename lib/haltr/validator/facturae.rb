module Haltr
  module Validator
    module Facturae

      def self.included(base)
        condition = Haltr::Validator.condition_for(Haltr::Validator::Facturae)
        base.class_eval do
          validates_length_of :file_reference, maximum: 20, if: condition
          validates_length_of :accounting_cost, maximum: 40, if: condition
          validates_length_of :delivery_note_number, maximum: 30, if: condition
          validate :facturae_validations, if: condition
        end
      end

      def facturae_validations
        # facturae 3.x needs taxes to be valid
        invoice_lines.each do |line|
          unless line.taxes_outputs.any?
            errors.add(:base, I18n.t(:invoice_has_no_taxes))
          end
        end

        # facturae needs taxcodes
        if company.blank? or company.taxcode.blank?
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
            errors.add(:payment_method, I18n.t(:requires_client_bank_account))
          end
        elsif transfer?
          bank_info = self.bank_info
          if !bank_info or (bank_info.bank_account.blank? and bank_info.iban.blank?)
            errors.add(:payment_method, I18n.t(:requires_company_bank_account))
          elsif (bank_info.bank_account.blank? and !bank_info.use_iban?)
            errors.add(:payment_method, I18n.t(:requires_company_bank_account))
            bank_info.errors.add(:base, :invalid)
          end
        end
        unless payment_method.blank?
          if due_date.blank?
            errors.add(:due_date, :blank)
          end
        end
        if currency != 'EUR'
          errors.add(:exchange_rate, :blank) unless exchange_rate.present?
          errors.add(:exchange_date, :blank) unless exchange_date.present?
        end

        if client.errors.any?
          errors.add(:client, client.errors.full_messages.uniq.join(', '))
        end
      end

    end
  end
end
