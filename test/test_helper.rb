require 'rubygems'
require 'spork'
#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'


Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.

  require  File.dirname(__FILE__) + '/haltr_test_helper'

  redmine_path = ENV['REDMINE_PATH'].nil? ? File.dirname(__FILE__) + '/../../../' : ENV['REDMINE_PATH']
  redmine_test_helper_path = File.expand_path(redmine_path + '/test/test_helper') 
  begin
    require redmine_test_helper_path
  rescue LoadError => e
    # we are alone
    puts("I'm a plugin. I need Redmine to run my tests. Please set env REDMINE_PATH='/path/to/redmine/install'.")
    raise e
  ensure
    puts ">> require '#{redmine_test_helper_path}'"
  end

  haltr_engine = Engines.plugins[:haltr]
  Engines::Testing.setup_plugin_fixtures([haltr_engine])
  Engines::Testing.set_fixture_path

  Haltr::TestHelper.haltr_setup

end

Spork.each_run do
  # This code will be run each time you run your specs.

  require  File.dirname(__FILE__) + '/haltr_test_helper'

  haltr_engine = Engines.plugins[:haltr]
  Engines::Testing.setup_plugin_fixtures([haltr_engine])
  Engines::Testing.set_fixture_path

end

