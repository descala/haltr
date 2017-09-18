module Haltr
  module Validator

    def self.condition_for(validator)
      Proc.new {|invoice|
        if invoice.client and invoice.client.invoice_format and
            invoice.about_to_be_sent? #TODO: check if !invoice.send_original? ?
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
