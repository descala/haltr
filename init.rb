require 'redmine'

Rails.logger.info 'Starting haltr plugin'

require_dependency 'haltr'

# Haltr has plugins of his own
# similar to config/initializers/00-core_plugins.rb in Redmine
# Loads the core plugins located in lib/plugins
Dir.glob(File.join(File.dirname(__FILE__), "lib/plugins/*")).sort.each do |directory|
  if File.directory?(directory)
    lib = File.join(directory, "lib")
    if File.directory?(lib)
      $:.unshift lib
      ActiveSupport::Dependencies.autoload_paths += [lib]
    end
    initializer = File.join(directory, "init.rb")
    if File.file?(initializer)
      config = config = RedmineApp::Application.config
      eval(File.read(initializer), binding, initializer)
    end
  end
end

Date::DATE_FORMATS[:ddmmyy] = "%d%m%y"

require_dependency 'utils'
require_dependency 'iso_countries'
require_dependency File.expand_path(File.join(File.dirname(__FILE__), 'app/models/export_channels'))

if (Redmine::VERSION::MAJOR == 1 and Redmine::VERSION::MINOR >= 4) or Redmine::VERSION::MAJOR == 2
  require_dependency 'country_iso_translater'
else
  config.gem 'sundawg_country_codes', :lib => 'country_iso_translater'
  config.gem 'money', :version => '>=5.0.0'
end

Rails.configuration.to_prepare do
  Project.send(:include, ProjectHaltrPatch)
  User.send(:include, UserHaltrPatch)
end

Redmine::Plugin.register :haltr do
  name 'haltr'
  author 'Ingent'
  description 'Hackers dont do books'
  version '1.2'

  settings :default => {
    'trace_url' => 'http://localhost:3000',
    'export_channels_path' => '/tmp',
    'issues_controller_name' => 'issues',
    'default_country' => 'es',
    'default_currency' => 'EUR',
    'hide_unauthorized' => '1'
  },
  :partial => '/common/settings'

  project_module :haltr do
    permission :general_use,
      { :clients  => [:index, :new, :edit, :create, :update, :destroy, :check_cif, :link_to_profile, :unlink,
                      :allow_link, :deny_link],
        :people   => [:index, :new, :show, :edit, :create, :update, :destroy],
        :invoices => [:index, :new, :edit, :create, :update, :destroy, :show, :mark_sent, :mark_closed, :mark_not_sent,
                      :destroy_payment, :facturae30, :facturae31, :facturae32, :peppolubl20, :send_invoice, :legal,
                      :update_payment_stuff, :amend_for_invoice, :download_new_invoices, :send_new_invoices, :duplicate_invoice,
                      :biiubl20, :svefaktura, :oioubl20, :efffubl, :report, :context_menu, :bulk_mark_as],
        :received => [:index, :new, :edit, :create, :update, :destroy, :show,
                      :mark_accepted, :mark_accepted_with_mail, :mark_refused,
                      :mark_refused_with_mail, :legal, :context_menu, :original,:validate, :bulk_mark_as],
        :companies => [:my_company,:update,:linked_to_mine]},
      :require => :member

    permission :manage_payments, { :payments => [:index, :new, :edit, :create, :update, :destroy, :payment_initiation, :n19, :payment_done, :import_aeb43_index,:import_aeb43 ] }, :require => :member
    permission :use_templates, { :invoice_templates => [:index, :new, :edit, :create, :update, :destroy, :show, :new_from_invoice,
                                 :new_invoices_from_template, :create_invoices, :update_taxes] }, :require => :member

    permission :use_all_readonly,
      { :clients  => [:index, :edit, :check_cif],
        :people   => [:index, :edit],
        :invoices => [:index, :show, :facturae30, :facturae31, :facturae32, :peppolubl20,
                      :legal, :download_new_invoices, :biiubl20, :svefaktura, :oioubl20, :efffubl, :report,
                      :context_menu],
        :received => [:index, :show, :legal, :context_menu],
        :companies => [:my_company, :update, :linked_to_mine],
        :payments => [:index, :n19],
        :invoice_templates => [:index, :show] }, :require => :member

    permission :bulk_operations,
      { :invoices => [:bulk_download,:bulk_send],
        :received => [:bulk_download,:bulk_validate] }, :require => :member

    permission :add_multiple_bank_infos,
      { :companies => [:add_bank_info] }, :require => :member

    permission :use_sepa,
      { :payments => [:sepa] }, :require => :member

    # Loads permisons from config/channels.yml
    ExportChannels.permissions.each do |permission,actions|
      permission permission, actions, :require => :member
    end

  end

  menu :project_menu, :companies,  { :controller => 'clients',  :action => 'index' }, :param => :project_id, :caption => :label_companies
  menu :project_menu, :invoices,   { :controller => 'invoices', :action => 'index' }, :param => :project_id, :caption => :label_invoice_plural
  menu :project_menu, :payments,   { :controller => 'payments', :action => 'index' }, :param => :project_id, :caption => :label_payment_plural
  # submenus defined at lib/haltr.rb

end

# avoid taxis error
ActiveSupport::Inflector.inflections do |inflect|
  inflect.singular 'taxes', 'tax'
end

Mime::Type.register "text/xml", :facturae30
Mime::Type.register "text/xml", :facturae31
Mime::Type.register "text/xml", :facturae32
Mime::Type.register "text/xml", :peppolubl20
Mime::Type.register "text/xml", :biiubl20
Mime::Type.register "text/xml", :svefaktura
Mime::Type.register "text/xml", :oioubl20
Mime::Type.register "text/xml", :efffubl
