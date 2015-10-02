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

require_dependency 'haltr/hooks'

if (Redmine::VERSION::MAJOR == 1 and Redmine::VERSION::MINOR >= 4) or Redmine::VERSION::MAJOR == 2
  require_dependency 'country_iso_translater'
else
  config.gem 'sundawg_country_codes', :lib => 'country_iso_translater'
  config.gem 'money', :version => '>=5.0.0'
end

Rails.configuration.to_prepare do
  Project.send(:include, ProjectHaltrPatch)
  User.send(:include, UserHaltrPatch)
  MyHelper.send(:include, ChartsHelper)
  MyHelper.send(:include, HaltrHelper)
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
    'hide_unauthorized' => '1',
    'return_path' => ''
  },
  :partial => '/common/settings'

  project_module :haltr do
    permission :general_use,
      { :clients   => [:index, :show, :new, :edit, :create, :update, :destroy, :check_cif, :link_to_profile, :unlink,
                       :allow_link, :deny_link, :ccc2iban],
        :people    => [:index, :new, :show, :edit, :create, :update, :destroy],
        :client_offices => [:index, :new, :show, :edit, :create, :update, :destroy],
        :invoices  => [:index, :new, :edit, :create, :update, :destroy, :show, :mark_sent, :mark_closed, :mark_not_sent,
                       :destroy_payment, :send_invoice, :legal, :update_payment_stuff, :amend_for_invoice, :download_new_invoices,
                       :send_new_invoices, :duplicate_invoice, :reports, :report_channel_state, :report_invoice_list, :context_menu, :bulk_mark_as, :original, :show_original,
                       :mark_as, :number_to_id],
        :received  => [:index, :new, :edit, :create, :update, :destroy, :show, :show_original,
                       :mark_accepted, :mark_accepted_with_mail, :mark_refused,
                       :mark_refused_with_mail, :legal, :context_menu, :original, :validate, :bulk_mark_as],
        :companies => [:my_company,:bank_info,:update,:linked_to_mine,:check_iban],
        :charts    => [:invoice_total, :invoice_status, :top_clients, :cash_flow],
        :events    => [:file] },
      :require => :member

    permission :manage_payments, { :payments => [:index, :new, :edit, :create, :update, :destroy, :payment_initiation, :n19, :payment_done, :import_aeb43_index, :import_aeb43, :invoices] }, :require => :member
    permission :use_templates, { :invoice_templates => [:index, :new, :edit, :create, :update, :destroy, :show, :new_from_invoice,
                                 :new_invoices_from_template, :create_invoices, :update_taxes, :context_menu] }, :require => :member

    permission :use_all_readonly,
      { :clients   => [:index, :edit, :check_cif, :ccc2iban],
        :people    => [:index, :edit],
        :client_offices => [:index, :edit],
        :invoices  => [:index, :show, :legal, :download_new_invoices, :reports, :report_channel_state, :report_invoice_list,
                       :context_menu, :show_original, :number_to_id, :edit],
        :received  => [:index, :show, :show_original, :legal, :context_menu],
        :companies => [:my_company,:bank_info, :linked_to_mine, :check_iban],
        :payments  => [:index, :n19],
        :invoice_templates => [:index, :show, :context_menu],
        :charts    => [:invoice_total, :invoice_status, :top_clients],
        :events    => [:file] },
      :require => :member

    permission :restricted_use,
      { :clients   => [:index, :edit, :check_cif, :ccc2iban, :update],
        :people    => [:index, :edit],
        :client_offices => [:index, :edit],
        :invoices  => [:index, :show, :legal, :download_new_invoices, :reports, :report_channel_state, :report_invoice_list,
                       :context_menu, :show_original, :send_invoice,
                       :send_new_invoices, :number_to_id],
        :received  => [:index, :show, :show_original, :legal, :context_menu],
        :companies => [:my_company,:bank_info, :linked_to_mine, :check_iban],
        :payments  => [:index, :n19],
        :invoice_templates => [:index, :show, :context_menu],
        :charts    => [:invoice_total, :invoice_status, :top_clients],
        :events    => [:file] },
      :require => :member

    permission :bulk_operations,
      { :invoices => [:bulk_download,:bulk_send],
        :received => [:bulk_download,:bulk_validate] }, :require => :member

    permission :add_multiple_bank_infos,
      { :companies => [:add_bank_info] }, :require => :member

    permission :use_sepa,
      { :payments => [:sepa],
        :mandates => [:index,:new,:show,:create,:edit,:update,:destroy,:signed_doc] }, :require => :member

    permission :import_invoices,
      { :invoices => [:import,:import_facturae],
        :received => [:import],
        :import_errors => [:index, :create, :show, :destroy, :context_menu] },
      :require => :member

    permission :email_customization,   {:companies=>'customization'}, :require => :member
    permission :configure_connections, {:companies=>'connections'}, :require => :member

    permission :invoice_quotes,
      { :quotes => [:index, :new, :create, :show, :edit, :update, :send_quote,
                    :destroy, :accept, :refuse] }, :require => :member

    permission :view_invoice_extra_fields, {}

    permission :view_sequence_number, {}

    permission :export_invoices, {:invoices => [:index]}

    permission :use_invoice_attachments, { :attachments => :upload}

    permission :add_invoice_notes, { :invoices => :add_comment }

    permission :manage_external_companies, {
      :external_companies => [:index, :new, :create, :edit, :update, :destroy, :csv_import],
      :dir3_entities => [:index, :new, :create, :edit, :update, :destroy, :csv_import]
    }

    # Loads permisons from config/channels.yml
    ExportChannels.permissions.each do |permission,actions|
      permission permission, actions, :require => :member
    end

  end

  menu :project_menu, :my_company, {:controller=>'companies', :action=>'my_company'}, :param=>:project_id, :caption=>:label_my_company
  menu :project_menu, :companies,  {:controller=>'clients',   :action=>'index'     }, :param=>:project_id, :caption=>:label_companies
  menu :project_menu, :invoices,   {:controller=>'invoices',  :action=>'index'     }, :param=>:project_id, :caption=>:label_invoice_plural
  menu :project_menu, :payments,   {:controller=>'payments',  :action=>'index'     }, :param=>:project_id, :caption=>:label_payment_plural
  menu :admin_menu, :external_companies, {:controller=>'external_companies', :action=>'index'}, :caption=>:external_companies
  menu :admin_menu, :dir3_entities, {:controller=>'dir3_entities', :action=>'index'}, :caption=>:dir3_entities
  menu :admin_menu, :export_channels, {:controller=>'export_channels', :action=>'index'}, :caption=>:export_channels
  # submenus defined at lib/haltr.rb

end

# avoid taxis error
ActiveSupport::Inflector.inflections do |inflect|
  inflect.singular 'taxes', 'tax'
  inflect.irregular 'unitat_tramitadora', 'unitats_tramitadores'
  inflect.irregular 'organ_gestor', 'organs_gestors'
  inflect.irregular 'oficina_comptable', 'oficines_comptables'
  inflect.irregular 'organ_proponent', 'organs_proponents'
end

Mime::Type.register "text/xml", :facturae30
Mime::Type.register "text/xml", :facturae31
Mime::Type.register "text/xml", :facturae32
Mime::Type.register "text/xml", :peppolubl20
Mime::Type.register "text/xml", :peppolubl21
Mime::Type.register "text/xml", :biiubl20
Mime::Type.register "text/xml", :svefaktura
Mime::Type.register "text/xml", :oioubl20
Mime::Type.register "text/xml", :efffubl
Mime::Type.register "text/xml", :original

Redmine::Activity.map do |activity|
  activity.register :info_events, :class_name => 'Event'
  activity.register :error_events, :class_name => 'Event'
end

Delayed::Worker.max_attempts = 3
Audited.current_user_method = :find_current_user
