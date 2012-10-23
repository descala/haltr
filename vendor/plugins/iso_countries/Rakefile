require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the iso_countries plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the iso_countries plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'IsoCountries'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc 'Download an updated list from the iso website'
task :update do
  url = "http://www.iso.org/iso/iso3166_en_code_lists.txt"
  require 'open-uri'
  iso = open(url)
  require "iconv"
  conv = Iconv.new('utf8', 'latin1')
  require "unicode"

  File.open('lib/country_list.rb', 'w')  do |f|
    f.puts "module ISO"
    f.puts "  module Countries"
    f.puts "    COUNTRIES = {"
    
    # Skip the first two lines, as they don't contain country information
    iso.readline
    iso.readline
    
    countries = []
    iso.each_line do |line|
      country, code = line.split(';')
      code.chomp!
      country = Unicode.capitalize(conv.iconv(country))
      
      puts "#{code} => #{country}"
      countries << "      :#{code.downcase} => N_(\"#{country}\")"
    end
    f.puts countries.join(",\n")
    
    f.puts "  }"
    f.puts "  end"
    f.puts "end"
  end
  
end

desc "Update pot/po files to match new version." 
task :updatepo do
  require 'gettext'
  require 'gettext/utils'  

  # GetText::ActiveRecordParser.init(:use_classname => false, :activerecord_classes => ['FakeARClass'])
  GetText.update_pofiles('iso_countries', 
                         Dir.glob("lib/**/*.rb"),
                         "iso_countries plugin")
end

desc "Create mo-files"
task :makemo do
  require 'gettext'
  require 'gettext/utils'  
  GetText.create_mofiles(true, "po", "locale")
end

desc "Downloads translations from iso-codes repository"
task :download do
  repo = "svn://svn.debian.org/pkg-isocodes/trunk/iso-codes/iso_3166"
  
  FileUtils.rm_rf("tmp")
  system "svn co #{repo} tmp"
  Dir.glob("tmp/*.po").each do |pofile|
    locale = File.basename(pofile, ".po")
    FileUtils.mkdir_p("po/#{locale}")
    puts "#{locale} -> po/#{locale}/iso_countries.po"
    FileUtils.mv(pofile, "po/#{locale}/iso_countries.po")
  end
  FileUtils.rm_rf("tmp")
end


spec = Gem::Specification.new do |s|
  s.name = "iso_countries"
  s.version = "0.1"
  s.author = "Jorge Bernal"
  s.email = "jbernal@warp.es"
  s.homepage = "http://github.com/koke/iso_countries"
  s.platform = Gem::Platform::RUBY
  s.summary = "Country selector with ISO codes"
  s.files = FileList["README*",
                                 "MIT-LICENSE",
                                 "Rakefile",
                                 "init.rb",
                                 "{lib,tasks,test}/**/*"].to_a
  s.require_path = "lib"
  s.test_files = FileList["test/**/test_*.rb"].to_a
  s.rubyforge_project = "iso_countries"
  s.has_rdoc = false
  s.extra_rdoc_files = FileList["README*"].to_a
  s.rdoc_options << '--line-numbers' << '--inline-source'
  s.requirements << "gettext"
end

desc "Generate a gemspec file for GitHub"
task :gemspec do
  File.open("#{spec.name}.gemspec", 'w') do |f|
    f.write spec.to_ruby
  end
end