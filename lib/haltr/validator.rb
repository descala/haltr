module Haltr
  module Validator

    def self.condition_for(validator)
      Proc.new {|invoice|
        return false unless invoice.client
        ExportChannels.validators(
          invoice.client.invoice_format
        ).include?(validator)
      }
    end

  end
end
