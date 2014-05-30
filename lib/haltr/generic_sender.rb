# Generic sender for delayed job

module Haltr
  class GenericSender

    attr_accessor :invoice, :user

    def initialize(invoice=nil, user=nil)
      self.invoice = invoice
      self.user    = user
    end

    def perform
      # implement!
    end

    # called if job has successfully run
    def success(job)
      create_event("success_sending")
    end

    # called if job has reached max retries, so cancelled
    def failure(job)
      create_event("discard_sending")
    end

    # called whenever job raises an error (once per retry)
    def error(job, error)
      HiddenEvent.create(:name      => "error",
                         :invoice   => invoice,
                         :error     => error.message,
                         :backtrace => error.backtrace)
    end

    def create_event(name)
      Event.create!(:name           => name,
                    :invoice        => invoice,
                    :notes          => invoice.client.email,
                    :class_for_send => self.class.to_s.split('::').last.underscore)
    end

  end
end
