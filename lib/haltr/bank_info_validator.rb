module Haltr::BankInfoValidator

  def self.included(base)
    base.class_eval do
      validates_numericality_of :bank_account, :allow_nil => true, :allow_blank => true
      validates_length_of :bank_account, :maximum => 20, :allow_nil => true, :allow_blank => true
      validates_length_of :bic, :in => 8..11, :allow_nil => true, :allow_blank => true

      validate :check_iban_is_ok

      def check_iban_is_ok
        errors.add(:base, :iban_is_invalid) if !iban.blank? and !IBANTools::IBAN.valid?(iban)
      end

      def use_iban?
        IBANTools::IBAN.valid?(iban)
      end

      def bank_account=(s)
        write_attribute(:bank_account, s.try(:gsub,/\p{^Alnum}/, ''))
      end

      def iban=(s)
        clean_iban = s.try(:gsub,/\p{^Alnum}/, '')
        write_attribute(:iban, IBANTools::IBAN.new(clean_iban).code)
      end

      def bic=(s)
        write_attribute(:bic, s.try(:gsub,/\p{^Alnum}/, ''))
      end

    end
  end

end
