ActionController::Routing::Routes.draw do |map|
  map.connect '/tasks/report/:id/:months_ago', :controller => 'tasks', :action => 'report'
  map.resources :invoices, :has_many => :events, :collection => { :by_taxcode_and_num => :get }
  map.resources :events
  map.connect '/invoices/legal/:id.:format', :controller => 'invoices', :action => 'legal'
end
