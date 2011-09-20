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

  FACTURAE = {
    "IVA" => 1,
    "VAT" => 1
  }

  UBL = {
    "IVA" => 2,
    "VAT" => 2
  }

end

