require File.expand_path('../../../../test/test_helper', __FILE__)

module Haltr
  module TestHelper

    # method to obtain local IP address
    require 'socket'
    def self.my_first_private_ipv4
      Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
    end

    def self.haltr_setup

      # Plugin config
      Setting.plugin_haltr = { "trace_url"              => "http://127.0.0.1",
                               "b2brouter_ip"           => my_first_private_ipv4.ip_address,
                               "export_channels_path"   => "#{ENV['HOME']}/git/b2brouter/spool/input",
                               "default_country"        => "es",
                               "default_currency"       => "EUR",
                               "issues_controller_name" => "issues",
                               "return_path"            => 'noreply@haltr.net' }
      Setting.rest_api_enabled = '1'

      # Enables haltr module on project 'OnlineStore'
      Project.find(2).enabled_modules << EnabledModule.new(:name => 'haltr')

      # Adds all haltr permissions to role 'delveloper'
      dev = Role.find(2)
      dev.permissions += Redmine::AccessControl.permissions.collect{|p| p.name if p.project_module==:haltr}.compact
      dev.save

      # user 2 (jsmith) is member of project 2 (onlinesotre) with role 2 (developer)

    end

    def self.fix_invoice_totals
      #Invoice.all.each do |i|
      #  puts "invoice invalid: #{i} (#{i.errors.full_messages.join})" unless i.valid?
      #end
      # ensure totals are ok for invoice fixtures
      Invoice.all.each do |i|
        i.save(validate: false)
      end
    end

  end
end

Haltr::TestHelper.haltr_setup
I18n.locale = :en

class ActiveSupport::TestCase
  self.fixture_path = File.dirname(__FILE__) + '/fixtures'
#  self.use_transactional_fixtures = true
#  self.use_instantiated_fixtures  = true
end

class ActionDispatch::IntegrationTest
  self.fixture_path = File.dirname(__FILE__) + '/fixtures'
#  self.use_transactional_fixtures = true
#  self.use_instantiated_fixtures  = true
end
