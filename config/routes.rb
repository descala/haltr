if Redmine::VERSION::MAJOR == 1

  ActionController::Routing::Routes.draw do |map|
    map.connect '/tasks/report/:id/:months_ago', :controller => 'tasks', :action => 'report'
    map.resources :invoices, :has_many => :events, :collection => { :by_taxcode_and_num => :get }
    map.resources :events
    map.connect '/invoices/logo/:id/:filename', :controller => 'invoices', :action => 'logo', :id => /\d+/, :filename => /.*/
    map.connect '/invoices/legal/:id.:format', :controller => 'invoices', :action => 'legal'
    map.connect '/invoice/download/:id/:invoice_id', :controller => 'invoices', :action => 'download', :id => /.*/, :invoice_id => /\d+/
    map.connect '/invoice/:id/:invoice_id', :controller => 'invoices', :action => 'view', :id => /.*/, :invoice_id => /\d+/
    map.connect '/statistics', :controller => 'stastics', :action => 'index'
    map.connect '/invoices/:action/:id', :controller => 'invoices'
    map.connect '/received/:action/:id', :controller => 'received'
    map.connect '/templates/:action/:id', :controller => 'invoice_templates'
    map.connect '/clients/:action/:id', :controller => 'clients'
    map.connect '/companies/:action/:id', :controller => 'companies'
    map.connect '/payments/:action/:id', :controller => 'payments'
    map.connect '/tasks/:action/:id', :controller => 'tasks'
    map.connect '/people/:action/:id', :controller => 'people'
  end

else
  # NOTE: all xml and json requests will use Redmine's API auth
  #        %w(xml json).include? params[:format]
  match '/tasks/report/:id/:months_ago' => 'tasks#report'
  resources :events
  match '/invoices/logo/:id/:filename' => 'invoices#logo', :id => /\d+/, :filename => /.*/
  match '/invoice/download/:id/:invoice_id' => 'invoices#download', :id => /.*/, :invoice_id => /\d+/
  match '/invoice/:id/:invoice_id' => 'invoices#view', :id => /.*/, :invoice_id => /\d+/
  match '/statistics' => 'stastics#index'

  match '/clients/check_cif/:id' => 'clients#check_cif', :via => :get
  match '/clients/link_to_profile/:id' => 'clients#link_to_profile', :via => :get
  match '/clients/unlink/:id' => 'clients#unlink', :via => :get
  match '/clients/allow_link/:id' => 'clients#allow_link', :via => :get
  match '/clients/deny_link/:id' => 'clients#deny_link', :via => :get
  resources :projects do
    resources :clients, :only => [:index, :new, :create]
    match :people, :controller => 'people', :action => 'index', :via => :get
    match 'companies/linked_to_mine', :controller => 'companies', :action => 'linked_to_mine', :via => :get
    resources :companies, :only => [:index]
    match 'invoices/send_new' => 'invoices#send_new_invoices', :via => :get
    match 'invoices/download_new' => 'invoices#download_new_invoices', :via => :get
    match 'invoices/update_payment_stuff' => 'invoices#update_payment_stuff', :via => :get
    resources :invoices, :only => [:index, :new, :create]
    resources :received, :only => [:index, :new, :create]
    resources :invoice_templates, :only => [:index, :new, :create]
    match 'report/issued_3m' => 'tasks#report', :via => :get
    resources :payments, :only => [:index, :new, :create]
    resources :tasks
    match 'tasks/import_aeb43' => 'tasks#import_aeb43'
  end
  match 'tasks/n19/:id' => 'tasks#n19'
  match 'tasks/n19_done/:id' => 'tasks#n19_done'
  resources :clients do
    resources :people, :only => [:index, :new, :create]
  end

  resources :people
  resources :invoices
  resources :invoices, :has_many => :events, :collection => { :by_taxcode_and_num => :get }
  resources :received
  resources :invoice_templates
  resources :payments

  match '/companies/logo/:taxcode' => 'companies#logo', :via => :get
  resources :companies, :only => [:update]


end
