class ExportChannels 

  unloadable

  def self.available
    # See config/channels.yml.example
    YAML.load(File.read( "#{RAILS_ROOT}/vendor/plugins/haltr/config/channels.yml"))
  rescue Exception => e
    puts "Exception while retrieving channels.yml: #{e.message}"
    {}
  end

  def self.permissions
    channel_permissions = {}
    self.available.values.each do |channel|
      channel["allowed_permissions"].each do |permission,actions|
        channel_permissions[permission] ||= {}
        channel_permissions[permission].merge!(actions) if actions
      end
    end
    channel_permissions
  end

  def self.default
    'signed_pdf'
  end

  def self.available?(id)
    available.include? id
  end

  def self.format(id)
    available[id]["format"] if available? id
  end

  def self.channel(id)
    available[id]["folder"] if available? id
  end

  def self.validations(id)
    return [] if available[id].nil? or available[id]["validate"].nil?
    available[id]["validate"].is_a?(Array) ? available[id]["validate"] : [available[id]["validate"]]
  end

  def self.for_select(current_project)
    available.collect {|k,v|
      unless User.current.admin?
        allowed = false
        v["allowed_permissions"].each_key do |perm|
          allowed = true if User.current.allowed_to?(perm, current_project)
        end
        next unless allowed
      end
      [ v["locales"][I18n.locale.to_s], k ]
    }.compact.sort {|a,b| a[1] <=> b[1] }
  end

  def self.path(id)
    part1 = "#{Setting.plugin_haltr['export_channels_path']}/#{self.channel(id)}"
  end
end

