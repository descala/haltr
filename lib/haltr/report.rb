module Haltr
  module Report
    def self.channel_state(project=nil)
      channel_state_count = {}
      state_totals = {}
      channel_totals = {}
      total_count = 0
      # {["facturae_32", "accepted"]=>1,
      #  ["facturae_32", "new"]=>8,
      #  ["facturae_32", "sent"]=>4}
      query = IssuedInvoice.includes('client')
      query = query.where("invoices.project_id=#{project.id}") if project
      result = query.group(['clients.invoice_format','state']).count
      result.each do |k,v|
        channel = k.first
        state = k.second
        state_totals[state] = state_totals[state].to_i + v
        channel_totals[channel] = channel_totals[channel].to_i + v
        channel_state_count[channel] = Hash.new if channel_state_count[channel].nil?
        channel_state_count[channel][state] = v
        total_count = total_count + v
      end
      return state_totals, channel_totals, channel_state_count, total_count
    end
  end
end
