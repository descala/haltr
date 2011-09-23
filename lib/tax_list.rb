module TaxList

  def self.facturae(tax_name)
    TaxList.check(FACTURAE,tax_name)
  end

  def self.ubl(tax_name)
    TaxList.check(UBL,tax_name)
  end

  def self.check(list,tax_name)
    t = tax_name.downcase.gsub(/[\. -]/,'')
    if list.values.flatten.include?(t)
      list.each do |k,v|
        return k if v.include? t
      end
    end
    nil
  end

  FACTURAE = {
    "01" => %w( iva vat ),
    "04" => %w( irpf ),
    "05" => %w( other altres otros )
  }

  UBL = {
    "VAT" => %w( vat iva ),
    "OTH" => %w( irpf other altres otros )
  }

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

  COUNTRY_TAXES = {
    "es" => { "IVA" => [4,8,18], "IRPF" => [-15,-19] },
    "es_default" => { "IVA" => 18 }
  }

end

