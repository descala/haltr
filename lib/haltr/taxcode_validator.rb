module Haltr::TaxcodeValidator

  # If you want to update all exiting taxcodes run these:
  #
  #  ExternalCompany.where("taxcode is not null and taxcode != ''").collect{|c| c if c.eu? and !Valvat::Checksum.validate(c.taxcode)}.compact.each{|c|c.save}
  #          Company.where("taxcode is not null and taxcode != ''").collect{|c| c if c.eu? and !Valvat::Checksum.validate(c.taxcode)}.compact.each{|c|c.save}
  #           Client.where("taxcode is not null and taxcode != ''").collect{|c| c if c.eu? and !Valvat::Checksum.validate(c.taxcode)}.compact.each{|c|c.save}

  extend ActiveSupport::Concern

  included do
    before_validation :normalize_taxcode
    validates :taxcode, :valvat => {:match_country => :country, :checksum => true}, :if => :eu?

    def eu?
      Valvat::Utils::EU_COUNTRIES.include?(country.upcase)
    end

    def normalize_taxcode
      tc = Valvat::Utils.normalize(taxcode)
      if tc and eu? and !Valvat::Checksum.validate(tc) and !(tc[0..1]==country.upcase)
        tc = "#{country.upcase}#{tc}"
      end
      self.taxcode = tc
    end
  end

end

