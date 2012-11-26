module TaxList

  def self.facturae(tax_name)
    val = TaxList.check(FACTURAE,tax_name)
    val.nil? ? "05" : val
  end

  def self.ubl(tax_name)
    val = TaxList.check(UBL,tax_name)
    val.nil? ? "OTH" : val
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
    "01" => %w( iva vat tva ),
    "04" => %w( irpf )
  }

  UBL = {
    "VAT" => %w( vat iva tva )
  }

  def self.default_taxes_for(country)
    taxes = []
    if COUNTRY_TAXES[country]
      COUNTRY_TAXES[country].each do |name,percents|
        percents.each do |percent|
          default = COUNTRY_TAXES["#{country}_default"] &&
            COUNTRY_TAXES["#{country}_default"][name] &&
            COUNTRY_TAXES["#{country}_default"][name] == percent
          taxes << Tax.new(:name => name, :percent => percent, :default => default)
        end
      end
    end
    taxes
  end

  COUNTRY_TAXES = {
    "es" => { "IVA" => [4,10,21], "IRPF" => [-21] },
    "es_default" => { "IVA" => 21 },
    "fr" => { "TVA" => [2.1,5.5,19.6] },
    "fr_default" => { "TVA" => 19.6 },
    "se" => { "VAT" => [6,12,25] },
    "se_default" => { "VAT" => 25 },
    "dk" => {"MUMS" => [25] },
    "dk_default" => { "MUMS" => 25 }
  }

end

