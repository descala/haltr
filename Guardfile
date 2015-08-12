# A sample Guardfile
# More info at https://github.com/guard/guard#readme

H="plugins/haltr"

guard :minitest, :zeus => true, :all_on_start => false, :all_after_pass => false, :test_folders => ["#{H}/test"] do
  watch(%r{^#{H}/lib/(.+)\.rb$})                          { |m| "#{H}/test/#{m[1]}_test.rb" }
  watch(%r{^#{H}/lib/haltr/(.+)\.rb$})                    { |m| "#{H}/test/lib/#{m[1]}_test.rb" }
  watch(%r{^#{H}/lib/haltr/bank_info_validator.rb$})      { ["#{H}/test/unit/bank_info_test.rb", "#{H}/test/unit/client_test.rb"] }
  watch(%r{^#{H}/lib/haltr/xml_validation(.+)$})          { |m| "#{H}/test/functional/invoices_controller_test.rb" }
  watch(%r{^#{H}/app/models/(.+)\.rb$})                   { |m| "#{H}/test/unit/#{m[1]}_test.rb" }
  watch(%r{^#{H}/app/helpers/(.+)\.rb$})                  { |m| "#{H}/test/unit/#{m[1]}_test.rb" }
  watch(%r{^#{H}/app/models/invoice_line.rb$})            { "#{H}/test/unit/invoice_test.rb" }
  watch(%r{^#{H}/app/controllers/(.+)\.rb$})              { |m| "#{H}/test/functional/#{m[1]}_test.rb" }
  watch(%r{^#{H}/app/controllers/(.+)_controller\.rb$})              { |m| "#{H}/test/integration/api_test/#{m[1]}_test.rb" }
  watch(%r{^#{H}/app/views/.+\.erb$})                     { ["#{H}/test/functional", "#{H}/test/integration"] }
  watch(%r{^#{H}/test/.+_test\.rb$})
  watch("#{H}/app/controllers/application_controller.rb") { ["#{H}/test/functional", "#{H}/test/integration"] }
  watch("#{H}/app/controllers/invoices_controller.rb")    { "#{H}/test/integration/invoice_edit_test.rb" }
  watch("#{H}/app/controllers/clients_controller.rb")     { "#{H}/test/integration/client_create_test.rb" }
  watch("#{H}/test/test_helper.rb")                       { "#{H}/test" }
end

#notification :notifysend
notification :libnotify
