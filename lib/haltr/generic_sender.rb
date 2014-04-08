# Generic sender for delayed job

module Haltr
  class GenericSender < Struct.new(:invoice, :user)

    def perform
      # implement!
    end

    def failure(job)
      create_event("error_sending")
    end

    def success(job)
      create_event("success_sending")
    end

    def create_event(name)
      Event.create!(:name    => name,
                    :invoice => invoice,
                    :notes   => invoice.client.email)
    end

  end
end
