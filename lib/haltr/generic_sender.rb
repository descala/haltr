# Generic sender for delayed job

module Haltr
  class GenericSender < Struct.new(:invoice, :user)

    def perform
      # implement!
    end

    def failure(job)
      Event.create!(:name    => "error_sending",
                    :invoice => invoice,
                    :user    => user,
                    :notes   => invoice.client.email)
    end

    def success(job)
      Event.create!(:name    => "success_sending",
                    :invoice => invoice,
                    :user    => user,
                    :notes   => invoice.client.email)
    end

  end
end
