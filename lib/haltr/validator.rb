module Haltr
  module Validator

    def self.condition_for(validator)
      Proc.new {|invoice|
        if invoice.client and invoice.client.invoice_format
          ExportChannels.validators(
            invoice.client.invoice_format
          ).include?(validator)
        else
          false
        end
      }
    end

  end
end
