module Haltr
  module Validator
    module Invoice

      def self.validate(invoice)
        # restrict states from invoice can be sent from
        unless %w(new error discarded refused).include?(invoice.state)
          invoice.add_export_error(I18n.t(:state_not_allowed_for_sending, state: I18n.t("state_#{invoice.state}")))
        end
      end

    end
  end
end
