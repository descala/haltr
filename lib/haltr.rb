require 'project_haltr_patch'
gem 'state_machine', '>=0.9.4'
require 'state_machine'
gem 'money', '>=3.1.5'
require 'money'
Money.default_currency = Money::Currency.new("EUR")
require 'ares'
gem 'will_paginate', '>=2.3.14'
require 'will_paginate'
