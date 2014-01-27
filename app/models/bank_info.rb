class BankInfo < ActiveRecord::Base
  unloadable
  include Haltr::BankInfoValidator
  belongs_to :company
  has_many :invoices, :dependent => :nullify
  has_many :clients, :dependent => :nullify
  validate :has_one_account

  def has_one_account
    if [bank_account, iban, bic].compact.reject(&:blank?).empty?
      errors.add(:base, "empty values for bank_account, iban and bic")
    end
  end

  # used on dropdowns
  def name
    if read_attribute(:name).blank?
      return bank_account unless bank_account.blank?
      return iban         unless iban.blank?
      return bic          unless bic.blank?
    end
    return read_attribute(:name)
  end

  def bank_account=(s)
    write_attribute(:bank_account, s.try(:gsub,/\p{^Alnum}/, ''))
  end

  def iban=(s)
    write_attribute(:iban, s.try(:gsub,/\p{^Alnum}/, ''))
  end

  def bic=(s)
    write_attribute(:bic, s.try(:gsub,/\p{^Alnum}/, ''))
  end

  def self.bank_account_to_iban(bank_account, country)
    if country.size == 3
      country = SunDawg::CountryIsoTranslater.translate_standard(
        country.to_s.upcase,'alpha3','alpha2'
      )
    end
    num = "#{bank_account}#{country}00".downcase.each_byte.collect do |c|
      if c <= 57
        c.chr
      else
        c - 87
      end
    end.join.to_i
    # MOD97-10 from ISO 7064
    control = (98 - ( num % 97 )).to_s.rjust(2,'0')
    "#{country.upcase}#{control}#{bank_account}"
  end

end
