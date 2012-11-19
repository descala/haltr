require 'redmine'

RAILS_DEFAULT_LOGGER.info 'Starting haltr plugin'

# Patches to the Redmine core
require 'dispatcher'
require 'project_haltr_patch'
Dispatcher.to_prepare do
  Project.send(:include, ProjectHaltrPatch)
end

Date::DATE_FORMATS[:ddmmyy] = "%d%m%y"

Dir[File.join(directory,'vendor','plugins','*')].each do |dir|
  path = File.join(dir, 'lib')
  $LOAD_PATH << path
  ActiveSupport::Dependencies.load_paths << path
  ActiveSupport::Dependencies.load_once_paths.delete(path)
end

# channels can define its own permissions
channel_permissions = {}
ExportChannels.available.values.each do |channel|
  channel["allowed_permissions"].each do |permission,actions|
    channel_permissions[permission] ||= {}
    channel_permissions[permission].merge!(actions) if actions
  end
end

Redmine::Plugin.register :haltr do
  name 'haltr'
  author 'Ingent'
  description 'Hackers dont do books'
  version '1.1'

  settings :default => {
    'trace_url' => 'http://localhost:3000',
    'export_channels_path' => '/tmp',
    'issues_controller_name' => 'issues',
    'default_country' => 'es',
    'default_currency' => 'EUR'
  },
  :partial => '/common/settings'

  project_module :haltr do
    permission :general_use,
      { :clients  => [:index, :new, :edit, :create, :update, :destroy, :check_cif, :link_to_profile, :unlink,
                      :allow_link, :deny_link],
        :people   => [:index, :new, :show, :edit, :create, :update, :destroy],
        :invoices => [:index, :new, :edit, :create, :update, :destroy, :show, :mark_sent, :mark_closed, :mark_not_sent,
                      :mark_accepted, :mark_accepted_with_mail, :mark_refused, :mark_refused_with_mail, :destroy_payment,
                      :efactura30, :efactura31, :efactura32, :ubl21, :send_invoice, :log, :legal, :update_currency_select,
                      :amend_for_invoice, :download_new_invoices, :send_new_invoices, :duplicate_invoice],
        :tasks    => [:index, :n19, :n19_done, :report, :import_aeb43],
        :companies => [:index,:edit,:update]},
      :require => :member

    permission :manage_payments, { :payments => [:index, :new, :edit, :create, :update, :destroy ] }, :require => :member
    permission :use_templates, { :invoice_templates => [:index, :new, :edit, :create, :update, :destroy, :show, :new_from_invoice,
                                 :invoices, :create_invoices, :update_taxes] }, :require => :member

    channel_permissions.each do |permission,actions|
      puts "Setting permission #{permission}: #{actions.to_json}"
      permission permission, actions, :require => :member
    end

  end

  menu :project_menu, :haltr_community, { :controller => 'clients', :action => 'index' }, :caption => :label_companies
  menu :project_menu, :haltr_invoices, { :controller => 'invoices', :action => 'index' }, :caption => :label_invoice_plural
  menu :project_menu, :haltr_payments, { :controller => 'payments', :action => 'index' }, :caption => :label_payment_plural
  menu :top_menu, :haltr_stastics, { :controller => 'stastics', :action => 'index' }, :caption => :label_stastics, :if => Proc.new {User.current.admin?}

end

if Redmine::VERSION::MAJOR == 1 
  require_dependency 'utils'
  require_dependency 'iso_countries'
  if Redmine::VERSION::MINOR >= 4
    require_dependency 'country_iso_translater'
  else
    config.gem 'sundawg_country_codes', :lib => 'country_iso_translater'
    config.gem 'money', :version => '>=5.0.0'
  end
else
  raise "Redmine version #{Redmine::VERSION::STRING} not supported"
end

# avoid taxis error
ActiveSupport::Inflector.inflections do |inflect|
  inflect.singular 'taxes', 'tax'
end
