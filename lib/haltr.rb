require 'project_haltr_patch'
gem 'state_machine', '>=0.9.4'
require 'state_machine'
gem 'money', '>=3.1.5'
require 'money'
if Setting.plugin_haltr['default_currency']
  Money.default_currency = Money::Currency.new(Setting.plugin_haltr['default_currency'])
else
  Money.default_currency = Money::Currency.new("EUR")
end
require "utils"
