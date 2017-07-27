# encoding: utf-8

###############
# b2bnet only #
###############

module Haltr
  class SendOrderResponseByPeppol

    require 'digest'

    attr_accessor :order, :channel, :user

    def initialize(order: nil, channel: 'peppolbis21', user: nil)
      self.order = order
      self.user = user || User.current
      self.channel = channel
    end

    def immediate_perform(doc)
      ws_url = "#{Redmine::Configuration['ws_url']}transactions"
      params = {
        'transaction' => build_request(doc, ExportChannels.options(channel)),
        'token' => Redmine::Configuration['ws_token']
      }
      RestClient.post ws_url, params do
        |response, request, result, &block|
        case response.code
        when 200
          assigned_id=JSON(response)['id']
          url = "#{Redmine::Configuration['ws_url']}../../transactions/#{assigned_id}"
          HiddenEvent.new(info: {url: url}, order: order, user: user, name: 'transaction_open').save
        else
          raise JSON(response)['message']
        end
      end
    end

    def build_request(doc, options)
      haltr_url = Redmine::Configuration['haltr_url']
      if haltr_url =~ /test/ or haltr_url =~ /localhost/
        from_net = 'b2brouter_test'
      else
        from_net = 'b2brouter'
      end
      req                     = options || {}
      req['id']               = Digest::MD5.hexdigest(doc)
      req['payload']          = Haltr::Utils.compress(doc)
      req['payload_filename'] = payload_filename
      req['haltr_object_id']  = order.id
      req['haltr_object_type']= 'Order'
      req['haltr_url']        = haltr_url
      req['email']            = order.company.email
      req['haltr_project_id'] = main_project_identifier
      req['company_country']  = order.company.country
      #
      # b2bws Trace
      req['from_net'] = from_net
      req['from']  = order.company.taxcode rescue nil
      req['to']    = order.client.taxcode  rescue nil
      req['date']  = order.date            rescue nil
      req
    end

    def payload_filename
      begin
        I18n.locale = user.language
      rescue I18n::InvalidLocale
        I18n.locale = 'en'
      end
      if user.projects.count > 1
        "order_response_#{order.company.taxcode}_#{order.id}.xml"
      else
        "order_response_#{order.id}.xml"
      end
    end

    # An user may have access to various projects
    # We need to obtain the identifier of the main project of the main user
    # Assume the main user is the user with the lowset id
    def main_project_identifier
      begin
        order.project.users.order('id').first.project.identifier
      rescue
        order.project.identifier
      end
    end

  end
end
