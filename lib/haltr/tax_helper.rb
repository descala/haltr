module Haltr
  module TaxHelper

    def add_category_to_taxes
      Company.all.each do |company|
        guess_tax_category company
      end
    end

    def guess_tax_category(company)
      names = company.taxes.find :all, :group => :name
      names.each do |tax_grouped|
        name = tax_grouped.name
        taxes = company.taxes.find :all,  :conditions => ['name = ?', name]
        size = taxes.size
        position = 1
        taxes.sort.each do |tax|
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
          tax.save!
        end
      end
    end

  end
end
