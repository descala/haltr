ActionController::Routing::Routes.draw do |map|
    map.connect '/tasks/report/:id/:months_ago', :controller => 'tasks', :action => 'report'
end
