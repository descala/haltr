require 'project_haltr_patch'
gem 'money', '>=3.1.5'
require 'money'
Money.default_currency = Money::Currency.new("EUR")
