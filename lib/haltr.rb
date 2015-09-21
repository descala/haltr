require 'haltr/xml_validation'
require 'haltr/tax_helper'
require 'project_haltr_patch'
require 'haltr/utils'

# Dynamic nested forms using jQuery made easy
# https://github.com/nathanvda/cocoon
require 'cocoon/view_helpers'

require 'haltr/menu_item'

Redmine::MenuManager.map :companies_menu do |menu|
  menu.push :companies_level2, {:controller=>'clients', :action => 'index' }, :param => :project_id, :caption => :label_companies
  menu.push :linked_to_mine, {:controller=>'companies', :action => 'linked_to_mine' }, :param => :project_id, :if => Proc.new { |p|
    Client.all(:conditions => ['company_id = ?', p.company]).any?
  }
  menu.push :people, {:controller=>'people', :action => 'index' }, :param => :project_id
  menu.push :client_offices , {:controller=>'client_offices', :action => 'index' }, :param => :project_id
end

Redmine::MenuManager.map :my_company_menu do |menu|
  menu.push :my_company_level2, {:controller=>'companies', :action=>'my_company'}, :param=>:project_id, :caption=>:label_fiscal_data
  menu.push :bank_info,     {:controller=>'companies', :action=>'bank_info'},  :param=>:project_id, :caption=>:bank_info
  menu.push :connections,   {:controller=>'companies', :action=>'connections'}, :param=>:project_id, :caption=>:label_connections
  menu.push :customization, {:controller=>'companies', :action=>'customization'}, :param=>:project_id, :caption=>:label_customization
end

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
  menu.push :quotes, {:controller=>'quotes', :action=>'index' }, :param => :project_id, :caption => :label_quote_plural
  menu.push :reports, {:controller=>'invoices', :action => 'reports' }, :param => :project_id, :caption=>:label_reports
  menu.push :import_errors, {:controller=>'import_errors', :action=>'index' }, :param => :project_id, :caption => :import_errors
end

Redmine::MenuManager.map :payments_menu do |menu|
  menu.push :payments_level2, {:controller=>'payments',:action=>'index'}, :param => :project_id, :caption => :label_payment_plural
  menu.push :payment_initiation, {:controller=>'payments',:action=>'payment_initiation'}, :param => :project_id
  menu.push :import_aeb43, {:controller=>'payments',:action=>'import_aeb43_index'}, :param => :project_id
  menu.push :mandates, {:controller=>'mandates',:action=>'index'}, :param => :project_id
end
