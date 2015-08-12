module Haltr
  class BulkSender

    attr_accessor :user, :invoice_ids

    def initialize(invoice_ids, user)
      self.invoice_ids = invoice_ids
      self.user = user
    end

    def perform
      IssuedInvoice.find(invoice_ids).each do |invoice|
        Rails.logger.info("[BulkSender] TRYING invoice  #{invoice.id}")
        unless invoice.new?
          Rails.logger.info("[BulkSender] SKIPED invoice  #{invoice.id} (state: #{invoice.state})")
          next
        end
        begin
          Haltr::Sender.send_invoice(invoice, user)
          invoice.queue(user)
          Rails.logger.info("[BulkSender] SENT   invoice  #{invoice.id}")
        rescue Exception => error
          begin
            HiddenEvent.create(:name      => "error",
                               :invoice   => invoice,
                               :error     => error.message,
                               :backtrace => error.backtrace)
            Rails.logger.info("[BulkSender] ERROR  invoice  #{invoice.id} (#{error})")
          rescue Exception => e
            Rails.logger.error("[BulkSender] ERROR creating HiddenEvent: (#{e})")
          end
        end
      end
    end

  end
end
