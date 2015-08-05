class ExportChannels 

  unloadable

  def self.use_file(file)
    @@channels = File.read(File.join(File.dirname(__FILE__), "../../config/#{file}"))
  end

  def self.available
    # See config/channels.yml.example
    @@channels ||= File.read(File.join(File.dirname(__FILE__), "../../config/channels.yml"))
    YAML.load(@@channels)
  rescue Exception => e
    puts "Exception while retrieving channels.yml: #{e.message}"
    {}
  end

  # all channels that can send
  def self.can_send
    self.available.reject {|c,v|
      v['folder'].nil? and v['class_for_send'].nil?
    }
  end

  def self.can_send?(id)
    self.can_send.keys.include? id
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

  def self.class_for_send(id)
    available[id]["class_for_send"] if available? id
  end

  def self.options(id)
    available[id]["options"] if available? id
  end

  def self.validators(id=nil)
    validators = []
    available.each do |name, channel|
      next if id and id != name
      if channel['validators'].is_a?(Array)
        validators += channel['validators']
      else
        validators << channel['validators']
      end
      if id and channel['format']
        validators += ExportFormats.validators(channel['format'])
      else
        validators += ExportFormats.validators
      end
    end
    validators.compact.collect do |validator|
      begin
        validator.constantize
      rescue NameError => e
        Rails.logger.error "error loading validator #{validator}: #{e}"
        nil
      end
    end.compact.uniq
  end

  def self.for_select(current_project)
    available.sort { |a,b|
      if a[1]['order'].blank? and b[1]['order'].blank?
        a[0].downcase <=> b[0].downcase
      elsif a[1]['order'].blank?
        1
      elsif b[1]['order'].blank?
        -1
      else
        a[1]['order'].to_i <=> b[1]['order'].to_i
      end
    }.collect {|k,v|
      unless User.current.admin?
        allowed = false
        v["allowed_permissions"].each_key do |perm|
          if current_project.nil?
            allowed = true if User.current.allowed_to?(perm, nil, {global: true})
          else
            allowed = true if User.current.allowed_to?(perm, current_project)
          end
        end
        next unless allowed
      end
      [ v["locales"][I18n.locale.to_s], k ]
    }.compact
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

  def self.punts_generals
    available.collect {|k,v|
      k if v["locales"]["ca"] =~ /punt general/i
    }.compact
  end

end

