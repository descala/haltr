#!/usr/bin/ruby
#

require "yaml"

langs = %w(ca da en es fr nl sv)

base = ARGV[0] || 'ca'
puts "base is #{base}"
base_translation = YAML.load(File.read "config/locales/#{base}.yml")[base]

langs.each do |lang|
  next if lang == base
  translation = YAML.load(File.read "config/locales/#{lang}.yml")[lang]
  puts "#"
  puts "cat >> config/locales/#{lang}.yml <<EOF"
  base_translation.each do |k,v|
    puts "  #{k}: #{v}" unless translation.keys.include? k
  end
  puts "EOF"
end
