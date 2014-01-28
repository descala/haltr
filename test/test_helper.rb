require File.dirname(__FILE__) + '../../test/test_helper'


module Haltr
  module TestHelper

    # method to obtain local IP address
    require 'socket'
    def self.my_first_private_ipv4
      Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
    end

    def self.haltr_setup

      # Plugin config
      Setting.plugin_haltr = { "trace_url"=>"http://127.0.0.1", "b2brouter_ip"=>my_first_private_ipv4.ip_address, "export_channels_path"=>"#{ENV['HOME']}/git/b2brouter/spool/input", "default_country"=>"es", "default_currency"=>"EUR", "issues_controller_name"=>"issues" }

      # Enables haltr module on project 'OnlineStore'
      Project.find(2).enabled_modules << EnabledModule.new(:name => 'haltr')

      # Adds all haltr permissions to role 'delveloper'
      dev = Role.find(2)
      dev.permissions += [:general_use,:manage_payments,:use_templates,:import_invoices, :use_sepa,:add_multiple_bank_infos,:bulk_operations]
      dev.save

      # user 2 (jsmith) is member of project 2 (onlinesotre) with role 2 (developer)

    end

    def self.fix_invoice_totals
      # ensure totals are ok for invoice fixtures
      Invoice.all.each do |i|
        i.save!
      end
    end

  end
end

Haltr::TestHelper.haltr_setup

class ActiveSupport::TestCase
  self.fixture_path = File.dirname(__FILE__) + '/fixtures'
#  self.use_transactional_fixtures = true
#  self.use_instantiated_fixtures  = true
end

class ActionController::IntegrationTest
  self.fixture_path = File.dirname(__FILE__) + '/fixtures'
#  self.use_transactional_fixtures = true
#  self.use_instantiated_fixtures  = true
end
