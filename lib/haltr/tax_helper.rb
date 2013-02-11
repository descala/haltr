module Haltr
  module TaxHelper

    def self.facturae(tax_name)
      val = self.check(FACTURAE,tax_name)
      val.nil? ? "05" : val
    end

    def self.ubl(tax_name)
      val = self.check(UBL,tax_name)
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

    def default_taxes_for(country)
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
      guess_tax_category(taxes)
    end

    COUNTRY_TAXES = {
      "es" => { "IVA"  => [ 10, 21 ],
                "IRPF" => [ -21 ] },
      "fr" => { "TVA"  => [ 2.1, 5.5, 19.6 ] },
      "se" => { "VAT"  => [ 6, 12, 25 ] },
      "dk" => { "MUMS" => [ 25 ] },
      "es_default" => { "IVA" => 21 },
      "fr_default" => { "TVA" => 19.6 },
      "se_default" => { "VAT" => 25 },
      "dk_default" => { "MUMS" => 25 }
    }

    def add_category_to_taxes
      Company.all.each do |company|
        company.taxes = guess_tax_category(company.taxes)
        company.save!
      end
    end

    def guess_tax_category(taxes)
      result = []
      names = taxes.collect {|t| t.name }.uniq
      names.each do |name|
        tax_group = taxes.collect {|t| t if t.name == name }.compact
        size = tax_group.size
        position = 1
        tax_group.sort.each do |tax|
          if tax.percent == 0.0
            tax.category='Z'
            size = size - 1
          else
            # sorted by percent
            if size > 1 and position == 1
              tax.category='AA'
            elsif position == size and size > 2
              tax.category='H'
            end
          position = position + 1
          end
          result << tax
        end
      end
      result
    end

  end
end
