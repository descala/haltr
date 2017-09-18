require 'haltr/xml_validation'
require 'haltr/tax_helper'
require 'project_haltr_patch'
require 'haltr/utils'

# Dynamic nested forms using jQuery made easy
# https://github.com/nathanvda/cocoon
require 'cocoon/view_helpers'

require 'haltr/menu_item'

Redmine::MenuManager.map :invoices_menu do |menu|
  menu.push :invoices_level2, {:controller=>'invoices', :action => 'index' }, :param => :project_id, :caption => :label_issued
  menu.push :templates, {:controller=>'invoice_templates', :action => 'index' }, :param => :project_id, :caption => :label_invoice_template_plural
  menu.push :received, {:controller=>'received', :action => 'index' }, :param => :project_id, :caption => Proc.new { |p|
    count = p.received_invoices.where('has_been_read=false').count
    if count > 0
      "#{::I18n.t(:label_received)} (#{count})"
    else
      ::I18n.t(:label_received)
    end
  }
  menu.push :reports, {:controller=>'invoices', :action => 'reports' }, :param => :project_id, :caption=>:label_reports
  # menu.push :import_errors, {:controller=>'import_errors', :action=>'index' }, :param => :project_id, :caption => :import_errors
end

Redmine::MenuManager.map :payments_menu do |menu|
  menu.push :payments_level2, {:controller=>'payments',:action=>'index'}, :param => :project_id, :caption => :label_payment_plural
  menu.push :payment_initiation, {:controller=>'payments',:action=>'payment_initiation'}, :param => :project_id
  menu.push :reports, {:controller=>'payments', :action => 'reports' }, :param => :project_id, :caption=>:label_reports
  menu.push :import_aeb43, {:controller=>'payments',:action=>'import_aeb43_index'}, :param => :project_id
  menu.push :mandates, {:controller=>'mandates',:action=>'index'}, :param => :project_id
end
