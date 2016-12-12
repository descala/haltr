module Haltr
  class BulkSender

    attr_accessor :user, :invoice_ids

    def initialize(invoice_ids, user)
      self.invoice_ids = invoice_ids
      self.user = user
    end

    def perform
      IssuedInvoice.find(invoice_ids).each do |invoice|
        log("TRYING invoice  #{invoice.id}")
        unless invoice.new?
          log("SKIPED invoice  #{invoice.id} (state: #{invoice.state})")
          next
        end
        begin
          Haltr::Sender.send_invoice(invoice, user)
          invoice.queue(user)
          log("SENT   invoice  #{invoice.id}")
        rescue Exception => error
          begin
            HiddenEvent.create(:name      => "error",
                               :invoice   => invoice,
                               :error     => error.message,
                               :backtrace => error.backtrace)
            log("ERROR  invoice  #{invoice.id} (#{error})")
          rescue Exception => e
            log("ERROR creating HiddenEvent: (#{e})", 'error')
          end
        end
      end
    end

    def log(msg, level='info')
      msg = "[BulkSender] - #{Time.now} - #{msg}"
      Rails.logger.send(level, msg)
    end

  end
end
