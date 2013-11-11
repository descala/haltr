class ExportFormats
  unloadable

  def self.available
    # See config/formats.yml.example
    @@formats ||= File.read(File.join(File.dirname(__FILE__), "../../config/formats.yml"))
    YAML.load(@@formats)
  rescue Exception => e
    puts "Exception while retrieving formats.yml: #{e.message}"
    {}
  end

  def self.available?(id)
    available.include? id
  end

  def self.validations(id)
    return [] if available[id].nil? or available[id]["validate"].nil?
    available[id]["validate"].is_a?(Array) ? available[id]["validate"] : [available[id]["validate"]]
  end

  def self.[](id)
    available[id]
  end

end
