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

end
