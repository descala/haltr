module ISO #:nodoc:
  module Countries #:nodoc:
    module CountryField #:nodoc:
      def self.included(base) #:nodoc:
        base.extend ClassMethods
      end
      
      module ClassMethods
        # Declares a field from a model as a iso code for a country
        #
        # Example:
        #
        #   class Company
        #     iso_country :country
        #   end
        # 
        #   c = Company.new(:country => "es")
        #   c.country_name # => "Spain"
        #   c.country_name = "France"
        #   c.country # => "fr"
        def iso_country(*args)
          args.each do |f|
            class_eval <<-EOC
              
              validates_inclusion_of :#{f}, :in => ISO::Countries.country_codes, :allow_nil => true
              
              def #{f}_name
                ISO::Countries.get_country(#{f})
              end
              
              def #{f}_name=(name)
                code = ISO::Countries.get_code(name)
                if code
                  self.#{f} = code
                else
                  raise ArgumentError, "Invalid country name"
                end
              end              
              
            EOC
          end
        end
      end
    end
  end
end
