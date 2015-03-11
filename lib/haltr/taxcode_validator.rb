module Haltr::TaxcodeValidator

  extend ActiveSupport::Concern

  included do
    before_validation :normalize_taxcode
    validates :taxcode, :valvat => {:match_country => :country, :checksum => true}, :if => :eu?

    def eu?
      Valvat::Utils::EU_COUNTRIES.include?(country.upcase)
    end

    def normalize_taxcode
      tc = Valvat::Utils.normalize(taxcode)
      if tc and eu? and !(tc[0..1] =~ /[A-Z]{2}/)
        tc = "#{country.upcase}#{tc}"
      end
      self.taxcode = tc
    end
  end

end

