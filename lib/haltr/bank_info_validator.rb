module Haltr::BankInfoValidator

  def self.included(base)
    base.class_eval {
      validates_numericality_of :bank_account, :allow_nil => true, :allow_blank => true
      validates_length_of :bank_account, :maximum => 20, :allow_nil => true, :allow_blank => true
      validates_length_of :bic, :in => 8..11, :allow_nil => true, :allow_blank => true
      validates_length_of :iban, :maximum => 24, :allow_nil => true, :allow_blank => true

      validate :check_iban_is_ok

      def check_iban_is_ok
        errors.add(:base, :iban_is_invalid) if !iban.blank? and !IBANTools::IBAN.valid?(iban)
      end

      def use_iban?
        IBANTools::IBAN.valid?(iban)
      end
    }
  end

end
