ActionController::Routing::Routes.draw do |map|
  map.connect '/tasks/report/:id/:months_ago', :controller => 'tasks', :action => 'report'
  map.resources :invoices, :has_many => :events, :collection => { :by_taxcode_and_num => :get }
  map.resources :events
  map.connect '/invoices/logo/:id/:filename', :controller => 'invoices', :action => 'logo', :id => /\d+/, :filename => /.*/
  map.connect '/invoices/legal/:id.:format', :controller => 'invoices', :action => 'legal'
  map.connect '/invoice/download/:id/:invoice_id', :controller => 'invoices', :action => 'download', :id => /.*/, :invoice_id => /\d+/
  map.connect '/invoice/:id/:invoice_id', :controller => 'invoices', :action => 'view', :id => /.*/, :invoice_id => /\d+/
end
