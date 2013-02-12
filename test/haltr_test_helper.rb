module Haltr
  module TestHelper
    class << self

      def haltr_setup

        # Plugin config
        Setting.plugin_haltr = { "trace_url"=>"http://localhost:3001", "b2brouter_ip"=>"", "export_channels_path"=>"/tmp", "default_country"=>"es", "default_currency"=>"EUR", "issues_controller_name"=>"issues" }

        # Enables haltr module on project 'OnlineStore'
       Project.find(2).enabled_modules << EnabledModule.new(:name => 'haltr')

        # Adds haltr permissions to role 'delveloper'
        dev = Role.find(2)
        dev.permissions += [:general_use]
        dev.save

        # user 2 (jsmith) is member of project 2 (onlinesotre) with role 2 (developer)

        # set jsmith project
        u = User.find(2)
        u.update_attribute(:project,Project.find(2))
      end

      def fix_invoice_totals
        # ensure totals are ok for invoice fixtures
        Invoice.all.each do |i|
          i.save!
        end
      end

    end
  end
end
