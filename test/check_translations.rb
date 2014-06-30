#!/usr/bin/ruby
#

require "yaml"

ca = YAML.load(File.read "config/locales/ca.yml")["ca"]
es = YAML.load(File.read "config/locales/es.yml")["es"]
en = YAML.load(File.read "config/locales/en.yml")["en"]
da = YAML.load(File.read "config/locales/da.yml")["da"]
fr = YAML.load(File.read "config/locales/fr.yml")["fr"]
sv = YAML.load(File.read "config/locales/sv.yml")["sv"]

%w(es en da fr sv).each do |lang|
  puts "comprovant #{lang}"
  ca.keys.each do |k|
    puts "falta traduccio de #{k} a #{lang}" unless eval(lang).keys.include? k
  end
end
