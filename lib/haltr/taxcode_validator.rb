module Haltr::TaxcodeValidator

  # If you want to update all exiting taxcodes run these:
  #
  #  ExternalCompany.where("taxcode is not null and taxcode != ''").collect{|c| c if c.eu? and !Valvat::Checksum.validate(c.taxcode)}.compact.each{|c|c.save}
  #          Company.where("taxcode is not null and taxcode != ''").collect{|c| c if c.eu? and !Valvat::Checksum.validate(c.taxcode)}.compact.each{|c|c.save}
  #           Client.where("taxcode is not null and taxcode != ''").collect{|c| c if c.eu? and !Valvat::Checksum.validate(c.taxcode)}.compact.each{|c|c.save}

  extend ActiveSupport::Concern

  included do

    before_validation :normalize_taxcode

    validates :taxcode, valvat: {
      match_country: :country,
      checksum:      true,
      allow_blank:   true,
    }, if: Proc.new {|c| c.gb? }

    validates_presence_of :company_identifier,
      if: Proc.new {|c| c.gb? and c.taxcode.blank? }

    validates :taxcode, :valvat => {
      match_country: :country,
      checksum:      true,
      allow_blank:   false,
    }, if: Proc.new {|c| !c.gb? and c.eu? }

    def eu?
      Valvat::Utils::EU_COUNTRIES.include?(country.upcase)
    end

    def gb?
      country == 'gb'
    end

    def normalize_taxcode
      tc = Valvat::Utils.normalize(taxcode)
      if tc and eu? and !Valvat::Checksum.validate(tc)
        # taxcode is not valid. try with country code prepended
        tc_with_contry_code = "#{country.upcase}#{tc}"
        tc = tc_with_contry_code if Valvat::Checksum.validate(tc_with_contry_code)
      end
      self.taxcode = tc
    end
  end

end

