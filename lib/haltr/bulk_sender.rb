module Haltr
  class BulkSender

    attr_accessor :invoices, :user

    def initialize(invoices, user)
      self.invoices = invoices
      self.user = user
    end

    def perform
      invoices.each do |invoice|
        Rails.logger.info("[BulkSender] TRYING invoice  #{invoice.id}")
        begin
          Haltr::Sender.send_invoice(invoice, user)
          invoice.queue || invoice.requeue
          Rails.logger.info("[BulkSender] SENT   invoice  #{invoice.id}")
        rescue Exception => error
          HiddenEvent.create(:name      => "error",
                             :invoice   => invoice,
                             :error     => error.message,
                             :backtrace => error.backtrace)
          Rails.logger.info("[BulkSender] ERROR  invoice  #{invoice.id} (#{error})")
        end
      end
    end

  end
end
