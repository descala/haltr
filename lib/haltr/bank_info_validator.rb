# encoding: utf-8
module Haltr::BankInfoValidator

  def self.included(base)
    base.class_eval do
      validates_length_of :bic, :in => 8..11, :allow_nil => true, :allow_blank => true

      validate :check_iban_is_ok

      def check_iban_is_ok
        # Do not enforce valid IBAN in "My Company"
        return true if self.is_a? BankInfo
        errors[:base] <<  l(:iban_is_invalid) if !iban.blank? and !IBANTools::IBAN.valid?(iban)
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
