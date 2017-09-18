module Haltr
  module FloatParser
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def float_parse(*fields)
        fields.each do |field|
          define_method("#{field}=") do |value|
            write_attribute(field, Haltr::Utils.float_parse(value))
          end
        end
      end
    end

  end
end
