source 'https://rubygems.org'

gem "money", "=5.0.0"
gem "state_machine"
gem "gettext"
gem "sundawg_country_codes" #, :lib => 'country_iso_translater'
gem "zip"
gem 'csv-mapper'
gem 'nokogiri', '< 1.6.0'
gem 'wicked_pdf'

group :test do
  gem 'spork-testunit'
  gem 'guard-spork'
  gem 'guard-test'
  gem 'rb-inotify', '~> 0.8.8'
end

# # Hack to test plugin
# if ENV["REDMINE_PATH"]
#   local_gemfile = File.join(ENV["REDMINE_PATH"], "Gemfile")
#   if File.exists?(local_gemfile)
#     if !defined? HALTR_RECURSION
#       # to not get evaluated again from Redmine
#       HALTR_RECURSION=true
#       puts "Loading Redmine's Gemfile ..." if $DEBUG # `ruby -d` or `bundle -v`
#       instance_eval File.read(local_gemfile)
#     end
#   end
# end
