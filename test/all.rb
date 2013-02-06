dir = File.dirname(File.expand_path(__FILE__))
Dir.glob(File.join(dir, "**", "*_test.rb")).each do |path|
  puts "Loading tests from #{path}"
  require path
end
