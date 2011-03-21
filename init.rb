require 'redmine'
require 'haltr'

RAILS_DEFAULT_LOGGER.info 'Starting haltr plugin'
Date::DATE_FORMATS[:ddmmyy] = "%d%m%y"

Dir[File.join(directory,'vendor','plugins','*')].each do |dir|
  path = File.join(dir, 'lib')
  $LOAD_PATH << path
  ActiveSupport::Dependencies.load_paths << path
  ActiveSupport::Dependencies.load_once_paths.delete(path)
end

Redmine::Plugin.register :haltr do
  name 'haltr'
  author 'Ingent'
  description 'Hackers dont do books'
  version '1.0'

  settings :default => {
    'trace_url' => 'http://localhost:3000',
    'export_channels_path' => '/tmp'
  },
  :partial => '/common/settings'

  project_module :haltr do
    permission :free_use,
      { :clients  => [:index, :new, :edit, :create, :update, :destroy, :check_cif, :link_to_profile, :unlink,
                      :allow_link, :deny_link],
        :people   => [:index, :new, :show, :edit, :create, :update, :destroy],
        :invoices => [:index, :new, :edit, :create, :update, :destroy, :show, :pdf, :template, :mark_sent,
                      :mark_closed, :mark_not_sent, :mark_accepted, :mark_accepted_with_mail, :mark_refused,
                      :mark_refused_with_mail, :destroy_payment, :efactura30, :efactura31, :efactura32, :ubl21,
                      :send_invoice, :log, :legal],
        :invoice_templates => [:index, :new, :edit, :create, :update, :destroy, :show, :new_from_invoice,
                               :invoices, :create_invoices],
        :tasks    => [:index, :n19, :n19_done, :report, :import_aeb43],
        :payments => [:index, :new, :edit, :create, :update, :destroy ],
        :companies => [:index,:edit,:update]},
      :require => :member
    permission :premium_use,
      {:tasks => [:automator]},
      :require => :member
  end

  menu :project_menu, :haltr_community, { :controller => 'clients', :action => 'index' }, :caption => :label_companies
  menu :project_menu, :haltr_invoices, { :controller => 'invoices', :action => 'index' }, :caption => :label_invoice_plural
  menu :project_menu, :haltr_payments, { :controller => 'payments', :action => 'index' }, :caption => :label_payment_plural

end

# https://github.com/koke/iso_countries/
require_dependency 'iso_countries'
# https://github.com/SunDawg/country_codes
config.gem 'sundawg_country_codes', :lib => 'country_iso_translater'
