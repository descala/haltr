ActionController::Routing::Routes.draw do |map|
  map.connect '/tasks/report/:id/:months_ago', :controller => 'tasks', :action => 'report'
  map.resources :invoices, :has_many => :events
  map.resources :events
end
