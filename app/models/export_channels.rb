class ExportChannels 

  unloadable

  def self.available
    # See config/channels.yml.example
    YAML.load(File.read( "#{RAILS_ROOT}/vendor/plugins/haltr/config/channels.yml"))
  rescue Exception => e
    puts "Exception while retrieving channels.yml: #{e.message}"
    {}
  end

  def self.default
    'signed_pdf'
  end

  def self.available?(id)
    available.include? id
  end

  def self.format(id)
    available[id][:format] if available? id
  end

  def self.channel(id)
    available[id][:folder] if available? id
  end

  def self.validations(id)
    return [] if available[id][:validate].nil?
    available[id][:validate].is_a?(Array) ? available[id][:validate] : [available[id][:validate]]
  end

  def self.for_select(current_project)
    available.collect {|k,v|
      unless User.current.admin?
        allowed = false
        v[:allowed_permissions].each do |perm|
          allowed = true if User.current.allowed_to?(perm, current_project)
        end
        next unless allowed
      end
      [ I18n.t(k), k ]
    }.compact.sort {|a,b| a[1] <=> b[1] }
  end

  def self.path(id)
    part1 = "#{Setting.plugin_haltr['export_channels_path']}/#{self.channel(id)}"
  end
end

