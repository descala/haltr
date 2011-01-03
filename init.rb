require 'redmine'
require 'haltr'

RAILS_DEFAULT_LOGGER.info 'Starting haltr plugin'

Date::DATE_FORMATS[:ddmmyy] = "%d%m%y"

Redmine::Plugin.register :haltr do
  name 'haltr'
  author 'Ingent'
  description 'Hackers dont do books'
  version '0.1'

  settings :default => {
    'folder1' => '',
    'folder1_name' => '',
    'folder2' => '',
    'folder2_name' => ''
  },
  :partial => '/common/settings'

  project_module :haltr do
    permission :free_use,
      { :clients  => [:index, :new, :edit, :create, :update, :destroy],
        :people   => [:index, :new, :show, :edit, :create, :update, :destroy],
        :invoices => [:index, :new, :edit, :create, :update, :destroy, :showit, :pdf, :template, :mark_sent, :mark_closed, :mark_not_sent, :destroy_payment, :efactura, :send_invoice, :log],
        :invoice_templates => [:index, :new, :edit, :create, :update, :destroy, :showit, :new_from_invoice],
        :tasks    => [:index, :create_more, :n19, :n19_done, :report, :import_aeb43],
        :payments => [:index, :new, :edit, :create, :update, :destroy ],
        :companies => [:index,:edit,:update]},
      :require => :member
    permission :premium_use,
      {:tasks => [:automator]},
      :require => :member
  end

  menu :project_menu, :haltr, { :controller => 'invoices', :action => 'index' }, :caption => :label_invoice_plural

end
