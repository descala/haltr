module TaxList

  def self.facturae(tax_name)
    TaxList.check(FACTURAE,tax_name)
  end

  def self.ubl(tax_name)
    TaxList.check(UBL,tax_name)
  end

  def self.check(list,tax_name)
    [tax_name, tax_name.gsub(/[\. -]/,'')].each do |t|
      return list[t] if list[t]
    end
    nil
  end

  def self.default_taxes_for(country)
    return nil unless COUNTRY_TAXES[country]
    taxes = []
    COUNTRY_TAXES[country].each do |name,percents|
      percents.each do |percent|
        default = COUNTRY_TAXES["#{country}_default"] &&
          COUNTRY_TAXES["#{country}_default"][name] &&
          COUNTRY_TAXES["#{country}_default"][name] == percent
        taxes << Tax.new(:name => name, :percent => percent, :default => default)
      end
    end
    taxes
  end

  FACTURAE = {
    "IVA" => 1,
    "VAT" => 1
  }

  UBL = {
    "IVA" => 2,
    "VAT" => 2
  }

  COUNTRY_TAXES = {
    "es" => { "IVA" => [4,8,18], "IRPF" => [-15,-19] },
    "es_default" => { "IVA" => 18 }
  }

end

