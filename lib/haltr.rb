gem 'state_machine', '>=0.9.4'
require 'state_machine'
gem 'money', '>=3.1.5'
require 'money'
require "utils"

require 'dispatcher'
require 'project_haltr_patch'

Dispatcher.to_prepare do
  Project.send(:include, ProjectHaltrPatch)
end
