module Haltr
  module Validator
    module Edifact

      def self.included(base)
        condition = Haltr::Validator.condition_for(Haltr::Validator::Edifact)
        base.class_eval do
          #TODO
        end
      end

    end
  end
end
