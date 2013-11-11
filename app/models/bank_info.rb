class BankInfo < ActiveRecord::Base
  unloadable
  belongs_to :company
  has_many :invoices, :dependent => :nullify

  validates_numericality_of :bank_account, :allow_nil => true, :allow_blank => true
  validates_length_of :bank_account, :maximum => 20
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

  # use iban and bic if they are present
  def use_iban?
    !(iban.nil? or bic.nil? or iban.blank? or bic.blank?)
  end

end
