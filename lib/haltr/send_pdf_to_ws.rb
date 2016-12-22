# encoding: utf-8

module Haltr
  class SendPdfToWs

    def self.send(invoice)
      req               = {}
      req['id']         = invoice.md5
      req['process']    = "Estructura::Invoice"
      req['invoice_id'] = invoice.id
      req['payload']    = invoice.read_attribute(:original) # already compressed
      req['payload_filename'] = payload_filename
      req['vat_id']     = invoice.company.taxcode
      req['is_issued']  = invoice.is_a? IssuedInvoice
      req['haltr_url']  = Redmine::Configuration['haltr_url']
      ws_url            = "#{Redmine::Configuration['ws_url']}transactions"
      RestClient.post(
        ws_url,
        { 'transaction' => req, 'token' => Redmine::Configuration['ws_token'] },
        {} # headers
      ) { |response, request, result, &block|
        if result.is_a?(Net::HTTPOK)
          #TODO puts "file sent to b2b_ws"
        else
          raise "FAILED - #{response} (#{result.message} #{result.code})"
          #TODO puts "FAILED - #{response} (#{result.message} #{result.code})"
        end
      }
      #TODO: rescue excepcions..
    end

    def self.payload_filename
      I18n.locale = User.current.language
      "#{I18n.t(:label_invoice)}.pdf"
    rescue
      "invoice.pdf"
    end

  end
end
