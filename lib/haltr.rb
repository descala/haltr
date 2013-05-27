require 'haltr/imap'
require 'haltr/xml_validation'
require 'haltr/tax_helper'
require 'project_haltr_patch'

# Dynamic nested forms using jQuery made easy
# https://github.com/nathanvda/cocoon
require 'cocoon/view_helpers'

Redmine::MenuManager.map :companies_menu do |menu|
#  menu.push :company_new, {:controller=>'clients', :action => 'new'}
  menu.push :companies, {:controller=>'clients', :action => 'index' }, :param => :project_id ,:caption => :label_companies
  menu.push :my_company, {:controller=>'companies', :action => 'index' }, :param => :project_id, :parent => :companies
  menu.push :people, {:controller=>'people', :action => 'index' }, :param => :project_id
  menu.push :people_l2, {:controller=>'people', :action => 'index' }, :param => :project_id, :parent => :people
end

