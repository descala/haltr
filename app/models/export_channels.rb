class ExportChannels 

  unloadable

  def self.available
    # See config/channels.yml.example
    @@channels ||= File.read(File.join(File.dirname(__FILE__), "../../config/channels.yml"))
    YAML.load(@@channels)
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

  def self.folder(id)
    available[id]["folder"] if available? id
  end

  def self.call_invoice_method(id)
    available[id]["call_invoice_method"] if available? id
  end

  def self.validations(id)
    return [] if available[id].nil?
    if available[id]["validate"].nil?
      validations = []
    else
      validations = available[id]["validate"].is_a?(Array) ? available[id]["validate"] : [available[id]["validate"]]
    end
    validations += ExportFormats.validations(available[id]["format"]) if available[id]["format"]
    validations.compact.uniq
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
    "#{Setting.plugin_haltr['export_channels_path']}/#{self.folder(id)}"
  end

  def self.l(channel_name)
    available[channel_name]['locales'][I18n.locale.to_s] rescue ''
  end

  def self.[](id)
    available[id]
  end

end

