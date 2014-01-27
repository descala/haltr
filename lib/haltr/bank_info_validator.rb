module Haltr::BankInfoValidator

  def self.included(base)
    base.class_eval {
      validates_numericality_of :bank_account, :allow_nil => true, :allow_blank => true
      validates_length_of :bank_account, :maximum => 20, :allow_nil => true, :allow_blank => true
      validates_length_of :bic, :in => 8..11, :allow_nil => true, :allow_blank => true
      validates_length_of :iban, :maximum => 24, :allow_nil => true, :allow_blank => true

      validate :iban_is_valid

      def iban_is_valid
        unless iban.blank?
          new_iban = IBANTools::IBAN.new(iban)
          new_iban.validation_errors.each do |e|
            errors.add(:iban, e)
          end
        end
      end


      # use iban and bic if they are present
      def use_iban?
        !(iban.nil? or bic.nil? or iban.blank? or bic.blank?)
      end
    }
  end

end
