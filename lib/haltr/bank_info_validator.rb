module Haltr::BankInfoValidator

  def self.included(base)
    base.class_eval {
      validates_numericality_of :bank_account, :allow_nil => true, :allow_blank => true
      validates_length_of :bank_account, :maximum => 20, :allow_nil => true, :allow_blank => true
      validates_length_of :bic, :in => 8..11, :allow_nil => true, :allow_blank => true
      validates_length_of :iban, :maximum => 24, :allow_nil => true, :allow_blank => true
      validate :has_one_account
      validate :iban_requires_bic

      def has_one_account
        if [bank_account, iban, bic].compact.reject(&:blank?).empty?
          errors.add(:base, "empty values for bank_account, iban and bic")
        end
      end

      def iban_requires_bic
        unless iban.blank? and bic.blank?
          errors.add(:base, "IBAN requires BIC") if iban.blank? or bic.blank?
        end
      end

      # use iban and bic if they are present
      def use_iban?
        !(iban.nil? or bic.nil? or iban.blank? or bic.blank?)
      end
    }
  end

end
