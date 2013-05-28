require 'haltr/imap'
require 'haltr/xml_validation'
require 'haltr/tax_helper'
require 'project_haltr_patch'

# Dynamic nested forms using jQuery made easy
# https://github.com/nathanvda/cocoon
require 'cocoon/view_helpers'

require 'haltr/menu_item'

Redmine::MenuManager.map :companies_menu do |menu|
  menu.push :companies_level2, {:controller=>'clients', :action => 'index' }, :param => :project_id ,:caption => :label_companies
  menu.push :my_company, {:controller=>'companies', :action => 'index' }, :param => :id
  menu.push :people, {:controller=>'people', :action => 'index' }, :param => :project_id
end

