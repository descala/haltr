# encoding: utf-8

module Haltr
  class SendPdfToWs

    def self.send(invoice)
      req               = {}
      req['id']         = invoice.md5
      req['process']    = "Estructura::Invoice"
      req['invoice_id'] = invoice.id
      req['payload']    = invoice.original # already compressed
      req['vat_id']     = invoice.company.taxcode
      req['is_issued']  = invoice.is_a? IssuedInvoice
      #TODO add api_key de l'usuari
      case Rails.env
      when 'production'
        req['haltr_url'] = 'https://www.b2brouter.net'
        ws_url           = 'https://ws.b2brouter.com/api/v1/transactions'
      when 'development', 'test'
        req['haltr_url'] = 'http://localhost:3001'
        ws_url           = 'http://localhost:3000/api/v1/transactions'
        #ws_url           = 'https://ws.b2brouter.com/api/v1/transactions'
      end

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

  end
end
