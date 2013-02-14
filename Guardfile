# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'spork', :cucumber_env => { 'RAILS_ENV' => 'test' }, :rspec_env => { 'RAILS_ENV' => 'test' }, :test_unit_env => { 'RAILS_ENV' => 'test' } do
  watch('Gemfile.lock')
  watch('test/test_helper.rb') { :test_unit }
end

guard :test, :drb => true do
  watch(%r{^lib/(.+)\.rb$})     { |m| "test/#{m[1]}_test.rb" }
  watch(%r{^lib/haltr/(.+)\.rb$})     { |m| "test/lib/#{m[1]}_test.rb" }
  watch(%r{^lib/haltr/xml_validation(.+)$})     { |m| "test/functional/invoices_controller_test.rb" }
  watch(%r{^test/.+_test\.rb$})
  watch('test/test_helper.rb')  { "test" }
  watch(%r{^app/models/(.+)\.rb$})                   { |m| "test/unit/#{m[1]}_test.rb" }
  watch(%r{^app/controllers/(.+)\.rb$})              { |m| "test/functional/#{m[1]}_test.rb" }
  watch(%r{^app/views/.+\.erb$})                     { ["test/functional", "test/integration"] }
  watch('app/controllers/application_controller.rb') { ["test/functional", "test/integration"] }

  watch('app/controllers/invoices_controller.rb') { "test/integration/invoice_edit_test.rb" }
end
