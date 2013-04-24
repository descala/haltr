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
      case country
      when 'es'
        taxes << Tax.new(:name=>'IVA',:percent=>21.0,:default=>true,:category=>'S')
        taxes << Tax.new(:name=>'IVA',:percent=>10.0,:default=>false,:category=>'AA')
        taxes << Tax.new(:name=>'IVA',:percent=>4.0, :default=>false,:category=>'AA')
        taxes << Tax.new(:name=>'IVA',:percent=>0.0, :default=>false,:category=>'Z')
        taxes << Tax.new(:name=>'IVA',:percent=>0.0, :default=>false,:category=>'E')
        taxes << Tax.new(:name=>'IRPF',:percent=>-21.0, :default=>false,:category=>'S')
      when 'fr'
        taxes << Tax.new(:name=>'TVA',:percent=>19.6,:default=>true,:category=>'S')
        taxes << Tax.new(:name=>'TVA',:percent=>5.5, :default=>false,:category=>'AA')
        taxes << Tax.new(:name=>'TVA',:percent=>2.1, :default=>false,:category=>'AAA')
      when 'se'
        taxes << Tax.new(:name=>'VAT',:percent=>25.0,:default=>true,:category=>'S')
        taxes << Tax.new(:name=>'VAT',:percent=>12.0,:default=>false,:category=>'AA')
        taxes << Tax.new(:name=>'VAT',:percent=>6.0, :default=>false,:category=>'AAA')
      when 'dk'
        taxes << Tax.new(:name=>'NUMS',:percent=>25.0,:default=>true,:category=>'S')
      end
    end

    def add_category_to_taxes
      Company.all.each do |company|
        company.taxes = guess_tax_category(company.taxes)
        company.save(false)
      end
    end

    def guess_tax_category(taxes)
      result = []
      names = taxes.collect {|t| t.name }.uniq
      names.each do |name|
        tax_group = taxes.collect {|t| t if t.name == name }.compact
        tax_group.sort.each_with_index do |tax,i|
          if tax.percent == 0.0
            tax.category='Z'
          elsif i == tax_group.size - 1
            tax.category='S'
          else
            tax.category='AA'
          end
          result << tax
        end
      end
      result
    end

  end
end
