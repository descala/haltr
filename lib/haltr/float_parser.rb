module Haltr
  module FloatParser
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def float_parse(*fields)
        fields.each do |field|
          define_method("#{field}=") do |value|
            val = case value.to_s
            when /^[0-9]+$/
              value
            when /^[0-9]+\.[0-9]+$/
              value
            when /^[0-9]+,[0-9]+$/
              value.gsub(/,/,'.')
            when /^[0-9\.]+,[0-9]+$/
              value.gsub(/\./,'').gsub(/,/,'.')
            when /^[0-9,]+.[0-9]+$/
              value.gsub(/,/,'')
            else
              '0'
            end
            write_attribute(field, val.to_f)
          end
        end
      end
    end

  end
end
