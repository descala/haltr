class ExportFormats


  def self.available
    # See config/formats.yml.example
    @@formats ||= YAML.load(File.read(File.join(File.dirname(__FILE__), "../../config/formats.yml")))
  rescue Exception => e
    puts "Exception while retrieving formats.yml: #{e.message}"
    {}
  end

  def self.available?(id)
    available.include? id
  end

  def self.validators(id=nil)
    validators = []
    available.each do |name, format|
      next if id and id != name
      if format['validators'].is_a?(Array)
        validators += format['validators']
      else
        validators << format['validators']
      end
    end
    validators.compact.uniq
  end

  def self.[](id)
    available[id]
  end

end
