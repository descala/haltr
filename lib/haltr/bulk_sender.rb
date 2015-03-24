module Haltr
  class BulkSender

    attr_accessor :invoices, :user

    def initialize(invoices, user)
      self.invoices = invoices
      self.user = user
    end

    def perform
      invoices.each do |invoice|
        begin
          Haltr::Sender.send_invoice(invoice, user)
          invoice.queue || invoice.requeue
        rescue Exception => error
          HiddenEvent.create(:name      => "error",
                             :invoice   => invoice,
                             :error     => error.message,
                             :backtrace => error.backtrace)
        end
      end
    end

  end
end
