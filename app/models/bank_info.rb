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

  def self.valid_spanish_ccc?(ccc)
    ccc=ccc.to_s.strip
    return false if ccc.blank? or ccc.size!=20

    valido = true

    suma = 0;
    suma += ccc[0].to_i * 4;
    suma += ccc[1].to_i * 8;
    suma += ccc[2].to_i * 5;
    suma += ccc[3].to_i * 10;
    suma += ccc[4].to_i * 9;
    suma += ccc[5].to_i * 7;
    suma += ccc[6].to_i * 3;
    suma += ccc[7].to_i * 6;
    division = (suma/11.0).floor;
    resto    = suma - (division  * 11);
    primer_digito_control = 11 - resto;
    primer_digito_control = 0 if primer_digito_control == 11
    primer_digito_control = 1 if primer_digito_control == 10
    valido = false if primer_digito_control != ccc[8].to_i

    suma = 0;
    suma += ccc[10].to_i * 1;
    suma += ccc[11].to_i * 2;
    suma += ccc[12].to_i * 4;
    suma += ccc[13].to_i * 8;
    suma += ccc[14].to_i * 5;
    suma += ccc[15].to_i * 10;
    suma += ccc[16].to_i * 9;
    suma += ccc[17].to_i * 7;
    suma += ccc[18].to_i * 3;
    suma += ccc[19].to_i * 6;
    division = (suma/11.0).floor;
    resto    = suma - (division  * 11);
    segundo_digito_control = 11 - resto;
    segundo_digito_control = 0 if segundo_digito_control == 11
    segundo_digito_control = 1 if segundo_digito_control == 10
    valido = false if segundo_digito_control != ccc[9].to_i


    return valido
  end

end
